#!/var/lib/openstack/bin/python3
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
"""Bring up ovs-vswitchd and, when opted in, migrate the host's primary
NIC onto an OVS bridge using systemd-networkd drop-ins.

Why systemd-networkd drop-ins rather than `ip addr add/del`:
on systemd-networkd hosts (Garden Linux), imperative address moves
leave networkd out of sync with the kernel. Its DHCP client keeps
trying to renew on the address-less NIC, eventually gives up, and
systemd-resolved drops the DHCP-learned upstream DNS servers.
Image pulls then fail with "Temporary failure in name resolution".

Takeover steps:
  1. Write .network drop-ins: $NIC = L2-only, $BR = DHCP=ipv4.
  2. Mask /usr/lib vendor .network files that match $NIC.
  3. ovs-vsctl add-port $BR $NIC (kernel L3 on $NIC now inactive).
  4. networkctl reload + reconfigure $BR (DHCP on the bridge).
  5. networkctl reconfigure $NIC (flush stale L3 on the NIC).

Step 4 runs before step 5 so systemd-resolved's upstream DNS list is
monotonically non-decreasing: [nic_dns] -> [nic_dns, br_dns] -> [br_dns].
No DNS gap; image pulls stay working throughout.
"""

import configparser
import os
import signal
import socket
import subprocess
import sys
import time
import uuid
from fnmatch import fnmatchcase
from pathlib import Path

from jinja2 import Environment, FileSystemLoader, StrictUndefined
from pyroute2 import IPRoute

TAKEOVER = os.environ.get("OVS_PHYSICAL_BRIDGE_TAKEOVER", "false").lower() == "true"
BR = os.environ.get("OVS_PHYSICAL_BRIDGE", "br-ovs0")
NIC_ENV = os.environ.get("PUBLIC_INTERFACE", "")

TEMPLATE_DIR = Path("/usr/local/share/ovs-vswitchd")
NETDIR = Path("/host/etc/systemd/network")
VENDOR_DIR = Path("/host/usr/lib/systemd/network")
IFACE_FILE = NETDIR / "10-ovs-uplink.network"
BR_FILE = NETDIR / f"15-{BR}.network"

DHCP_TIMEOUT_S = 30


def log(msg):
    print(f"start-ovs-vswitchd: {msg}", file=sys.stderr, flush=True)


def run(cmd, check=True):
    log(f"$ {' '.join(cmd)}")
    return subprocess.run(cmd, check=check)


def host(cmd):
    """networkctl is not in the loci image; run it in PID 1's mount namespace."""
    return run(["nsenter", "--mount", "--target", "1", "--"] + cmd)


# -----------------------------------------------------------------------------
# netlink helpers via pyroute2
# -----------------------------------------------------------------------------

def iface_index(ipr, name):
    idx = ipr.link_lookup(ifname=name)
    return idx[0] if idx else None


def iface_mac(ipr, name):
    idx = iface_index(ipr, name)
    if idx is None:
        raise SystemExit(f"interface {name} not found")
    for a in ipr.get_links(idx)[0]["attrs"]:
        if a[0] == "IFLA_ADDRESS":
            mac = a[1]
            if not mac or mac == "00:00:00:00:00:00":
                raise SystemExit(f"could not read MAC of {name}")
            return mac
    raise SystemExit(f"could not read MAC of {name}")


def iface_has_ipv4(ipr, name):
    idx = iface_index(ipr, name)
    if idx is None:
        return False
    return bool(ipr.get_addr(index=idx, family=socket.AF_INET))


def iface_ipv4(ipr, name):
    idx = iface_index(ipr, name)
    if idx is None:
        return ""
    for msg in ipr.get_addr(index=idx, family=socket.AF_INET):
        for a in msg["attrs"]:
            if a[0] == "IFA_ADDRESS":
                return a[1]
    return ""


def default_route_iface(ipr):
    for route in ipr.get_default_routes(family=socket.AF_INET):
        for a in route["attrs"]:
            if a[0] == "RTA_OIF":
                links = ipr.get_links(a[1])
                if links:
                    for la in links[0]["attrs"]:
                        if la[0] == "IFLA_IFNAME":
                            return la[1]
    return ""


def set_iface_mac(ipr, name, mac):
    idx = iface_index(ipr, name)
    if idx is None:
        raise SystemExit(f"interface {name} not found")
    ipr.link("set", index=idx, address=mac)


# -----------------------------------------------------------------------------
# OVS via ovs-vsctl (small number of one-shot calls; the IDL client is heavier
# than the code we'd save).
# -----------------------------------------------------------------------------

def vsctl(*args, check=True):
    return run(["ovs-vsctl"] + list(args), check=check)


def br_exists(name):
    return subprocess.run(["ovs-vsctl", "br-exists", name]).returncode == 0


def port_bridge(port):
    r = subprocess.run(["ovs-vsctl", "port-to-br", port],
                       capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""


# -----------------------------------------------------------------------------
# NIC / bridge selection
# -----------------------------------------------------------------------------

def resolve_nic(ipr):
    if NIC_ENV:
        return NIC_ENV
    if iface_index(ipr, "bond0") is not None:
        return "bond0"
    nic = default_route_iface(ipr)
    if not nic:
        raise SystemExit(
            "OVS_PHYSICAL_BRIDGE_TAKEOVER=true but PUBLIC_INTERFACE could not "
            "be determined (no bond0, no default route)"
        )
    return nic


# -----------------------------------------------------------------------------
# ovs-vswitchd bootstrap
# -----------------------------------------------------------------------------

def ovs_bootstrap():
    """Initialize OVSDB with system-type/version/system-id and start ovs-vswitchd."""
    if subprocess.run(["pgrep", "-f", "/usr/sbin/ovs-vswitchd"]).returncode == 0:
        raise SystemExit("Waiting to be the only highlander")

    ovs_version = subprocess.check_output(
        ["ovs-vsctl", "-V"], text=True
    ).splitlines()[0].split()[-1]
    ovs_db_version = subprocess.check_output(
        ["ovsdb-tool", "schema-version",
         "/usr/share/openvswitch/vswitch.ovsschema"],
        text=True,
    ).strip()
    sys_id = uuid.uuid4()

    for args in (
        ["init"],
        ["set", "Open_vSwitch", ".", f"db-version={ovs_db_version}"],
        ["set", "Open_vSwitch", ".", f"ovs-version={ovs_version}"],
        ["set", "Open_vSwitch", ".", "system-type=docker-ovs"],
        ["set", "Open_vSwitch", ".", "system-version=0.1"],
        ["set", "Open_vSwitch", ".", f"external-ids:system-id={sys_id}"],
        ["set-manager", "punix:/var/run/openvswitch/db.sock"],
    ):
        vsctl("--no-wait", "--", *args)
    run(["ovs-appctl", "-t", "ovsdb-server", "ovsdb-server/add-remote",
         "db:Open_vSwitch,Open_vSwitch,manager_options"])

    # Start ovs-vswitchd before any host mutation so an OVS failure leaves the
    # node intact.
    env = os.environ | {"XDG_RUNTIME_DIR": "/run/openvswitch"}
    log("starting ovs-vswitchd")
    return subprocess.Popen(
        [
            "/usr/sbin/ovs-vswitchd", "unix:/run/openvswitch/db.sock",
            "--mlockall", "--pidfile",
            "-vconsole:warn", "-vsyslog:info", "-vfile:off",
        ],
        env=env,
    )


# -----------------------------------------------------------------------------
# Vendor .network file masking
# -----------------------------------------------------------------------------

def vendor_matches_nic(vendor_file, nic, mac):
    """Parse a vendor .network's [Match] and decide whether it would apply
    to $NIC. Matches Name (glob), MACAddress (case-insensitive list), Type
    (ether covers physical NICs)."""
    cp = configparser.ConfigParser(strict=False, interpolation=None)
    cp.optionxform = str
    try:
        cp.read(vendor_file, encoding="utf-8")
    except configparser.Error:
        return False
    if not cp.has_section("Match"):
        return False
    match = cp["Match"]

    if mac.lower() in match.get("MACAddress", "").lower().split():
        return True
    for pat in match.get("Name", "").split():
        if fnmatchcase(nic, pat):
            return True
    if any("ether" in t for t in match.get("Type", "").split()):
        return True
    return False


def mask_vendor_files(nic, mac):
    """Symlink /host/etc/systemd/network/<basename> -> /dev/null for any
    vendor file whose [Match] would still apply to $NIC. Returns the list
    of masks written (for rollback)."""
    masked = []
    if not VENDOR_DIR.is_dir():
        return masked
    for vendor in sorted(VENDOR_DIR.glob("*.network")):
        etc_path = NETDIR / vendor.name
        if etc_path.exists() and not (
            etc_path.is_symlink() and os.readlink(etc_path) == "/dev/null"
        ):
            # Admin already customized this basename; do not touch.
            continue
        if not vendor_matches_nic(vendor, nic, mac):
            continue
        log(f"masking vendor file {vendor.name}")
        if etc_path.is_symlink() or etc_path.exists():
            etc_path.unlink()
        etc_path.symlink_to("/dev/null")
        masked.append(vendor.name)
    return masked


# -----------------------------------------------------------------------------
# Templates
# -----------------------------------------------------------------------------

def render(template_name, **ctx):
    env = Environment(
        loader=FileSystemLoader(str(TEMPLATE_DIR)),
        undefined=StrictUndefined,
        keep_trailing_newline=True,
    )
    return env.get_template(template_name).render(**ctx)


# -----------------------------------------------------------------------------
# Takeover
# -----------------------------------------------------------------------------

def wait_for_ipv4(ipr, iface, timeout=DHCP_TIMEOUT_S):
    for _ in range(timeout):
        if iface_has_ipv4(ipr, iface):
            return True
        time.sleep(1)
    return False


def already_done(ipr, nic):
    """Idempotency: $BR exists in OVSDB, $NIC is a port on it, and $BR has IPv4."""
    return br_exists(BR) and port_bridge(nic) == BR and iface_has_ipv4(ipr, BR)


def takeover(ipr, nic):
    """Rollback checkpoints:
        1 = drop-in files written
        2 = bridge MAC set
        3 = add-port done (kernel L3 on $NIC now inactive)
        4 = $BR reconfigured (DHCP started on $BR)
    """
    mac = iface_mac(ipr, nic)
    checkpoint = 0
    masked = []

    def rollback():
        log(f"takeover failed at CP={checkpoint}, rolling back")
        if checkpoint >= 3:
            vsctl("--if-exists", "del-port", BR, nic, check=False)
        if checkpoint >= 1:
            for p in (IFACE_FILE, BR_FILE):
                p.unlink(missing_ok=True)
            for name in masked:
                target = NETDIR / name
                if target.is_symlink() and os.readlink(target) == "/dev/null":
                    target.unlink()
            host(["networkctl", "reload"])
            host(["networkctl", "reconfigure", nic])

    try:
        NETDIR.mkdir(parents=True, exist_ok=True)

        # Match by Name, not MAC: the bridge will inherit $NIC's MAC below.
        IFACE_FILE.write_text(render("ovs-uplink.network.j2", nic=nic, br=BR))
        BR_FILE.write_text(render("ovs-bridge.network.j2", nic=nic, br=BR))
        checkpoint = 1

        masked = mask_vendor_files(nic, mac)

        # Pin the bridge to $NIC's MAC before add-port so upstream keeps the L2 identity.
        vsctl("--may-exist", "add-br", BR)
        vsctl("set", "bridge", BR, f"other-config:hwaddr={mac}")
        set_iface_mac(ipr, BR, mac)
        checkpoint = 2

        vsctl("--may-exist", "add-port", BR, nic)
        checkpoint = 3

        # Reconfigure $BR before $NIC so systemd-resolved learns $BR's DNS
        # before losing $NIC's — no upstream DNS gap.
        host(["networkctl", "reload"])
        host(["networkctl", "reconfigure", BR])
        checkpoint = 4

        host(["networkctl", "status", BR])
        host(["networkctl", "status", nic])

        if not wait_for_ipv4(ipr, BR):
            raise SystemExit(f"{BR} did not acquire DHCPv4 lease within {DHCP_TIMEOUT_S}s")

        # Converge upstream CAM tables onto the bridge port.
        br_ip = iface_ipv4(ipr, BR)
        if br_ip:
            run(["arping", "-q", "-c", "2", "-U", "-I", BR, br_ip], check=False)

        host(["networkctl", "reconfigure", nic])

        log(f"takeover done, {BR}={br_ip}, {nic} is OVS port")
    except BaseException:
        rollback()
        raise


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

def main():
    ovs_proc = ovs_bootstrap()
    signal.signal(signal.SIGTERM, lambda *_: ovs_proc.terminate())

    if TAKEOVER:
        with IPRoute() as ipr:
            nic = resolve_nic(ipr)
            if already_done(ipr, nic):
                log(f"takeover already done ({nic} in {BR}, {BR} has IPv4)")
            else:
                try:
                    takeover(ipr, nic)
                except BaseException:
                    ovs_proc.terminate()
                    raise

    ovs_proc.wait()
    sys.exit(ovs_proc.returncode)


if __name__ == "__main__":
    main()
