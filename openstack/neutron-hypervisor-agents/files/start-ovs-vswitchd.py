#!/var/lib/openstack/bin/python3
"""Start ovs-vswitchd and, when OVS_PHYSICAL_BRIDGE_TAKEOVER=true,
migrate the host's primary NIC onto an OVS bridge via systemd-networkd
drop-ins.

Imperative `ip addr add/del` desyncs systemd-networkd's DHCP client
from the kernel; systemd-resolved then drops upstream DNS and image
pulls fail. Writing .network drop-ins and letting `networkctl
reconfigure` migrate the lease keeps DNS continuous throughout.

On restart, the kernel datapath persists (openvswitch.ko is host-scope)
and OVSDB state is on disk. If both are present we take the hitless
path: set other_config:flow-restore-wait=true before spawning the new
ovs-vswitchd so it does not wipe kernel flows, replay the flows saved
by the preStop hook, then clear the flag. See ovs-lib(1)'s
flow_restore_wait / flow_restore_complete sequence.
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

NETDIR = Path("/host/etc/systemd/network")
VENDOR_DIR = Path("/host/usr/lib/systemd/network")
NSENTER = ["nsenter", "--mount", "--target", "1", "--"]  # networkctl lives in PID 1's mount ns
SAVED_FLOWS = Path("/run/openvswitch/saved-flows.sh")

TEMPLATE_DIR = Path("/usr/local/share/start-ovs-vswitchd")
JINJA = Environment(loader=FileSystemLoader(str(TEMPLATE_DIR)),
                    undefined=StrictUndefined, keep_trailing_newline=True)


def vendor_matches(vendor_file, nic, mac):
    """Would this /usr/lib .network's [Match] apply to $NIC?"""
    cp = configparser.ConfigParser(strict=False, interpolation=None)
    cp.optionxform = str
    try:
        cp.read(vendor_file, encoding="utf-8")
    except configparser.Error:
        return False
    m = cp["Match"] if cp.has_section("Match") else {}
    return (mac.lower() in m.get("MACAddress", "").lower().split()
            or any(fnmatchcase(nic, p) for p in m.get("Name", "").split())
            or any("ether" in t for t in m.get("Type", "").split()))


# --- Detect prior OVS state -------------------------------------------------

if subprocess.run(["pgrep", "-f", "/usr/sbin/ovs-vswitchd"], check=False).returncode == 0:
    print("ovs-vswitchd already running; nothing to do")
    sys.exit(0)

# Bridge in OVSDB from a previous incarnation? ovsdb-server sidecar starts
# before this container so ovs-vsctl works via the unix socket.
bridge_in_ovsdb = (
    subprocess.run(["ovs-vsctl", "br-exists", BR], check=False).returncode == 0
)
# Kernel datapath port for the bridge still present? openvswitch.ko is
# host-scope so it survives container exit.
bridge_in_kernel = Path(f"/sys/class/net/{BR}").exists()
hitless = bridge_in_ovsdb and bridge_in_kernel

# Defensive: clear any flow-restore-wait left behind by a crashed startup.
subprocess.run(["ovs-vsctl", "--if-exists", "remove", "Open_vSwitch", ".",
                "other_config", "flow-restore-wait"], check=False)

# --- Bootstrap OVSDB and start ovs-vswitchd ---------------------------------

ovs_version = subprocess.check_output(["ovs-vsctl", "-V"], text=True).split()[1]
ovs_db_version = subprocess.check_output(
    ["ovsdb-tool", "schema-version", "/usr/share/openvswitch/vswitch.ovsschema"],
    text=True,
).strip()
subprocess.run(
    ["ovs-vsctl", "--no-wait",
     "--", "init",
     "--", "set", "Open_vSwitch", ".",
           f"db-version={ovs_db_version}",
           f"ovs-version={ovs_version}",
           "system-type=docker-ovs",
           "system-version=0.1",
           f"external-ids:system-id={uuid.uuid4()}",
     "--", "set-manager", "punix:/var/run/openvswitch/db.sock"],
    check=True,
)
if hitless:
    # Prevent the new ovs-vswitchd from wiping kernel flows on startup.
    subprocess.run(["ovs-vsctl", "set", "Open_vSwitch", ".",
                    "other_config:flow-restore-wait=true"], check=True)

subprocess.run(
    ["ovs-appctl", "-t", "ovsdb-server",
     "ovsdb-server/add-remote", "db:Open_vSwitch,Open_vSwitch,manager_options"],
    check=True,
)

# subprocess.Popen is a context manager: on exit it terminates + waits the
# child, so an exception during takeover leaves no orphan ovs-vswitchd.
with subprocess.Popen(
    ["/usr/sbin/ovs-vswitchd", "unix:/run/openvswitch/db.sock",
     "--mlockall", "--pidfile",
     "-vconsole:warn", "-vsyslog:info", "-vfile:off"],
    env=os.environ | {"XDG_RUNTIME_DIR": "/run/openvswitch"},
) as ovs_proc:
    signal.signal(signal.SIGTERM, lambda *_: ovs_proc.terminate())

    if hitless:
        # Replay flows saved by the preStop hook so ovs-vswitchd's userspace
        # tables match the kernel flow cache before we clear flow-restore-wait.
        # Missing script is not fatal: ovn-controller will repopulate flows
        # from the Southbound DB (slower, but non-catastrophic).
        if SAVED_FLOWS.exists():
            subprocess.run([str(SAVED_FLOWS)], check=False)
            SAVED_FLOWS.unlink(missing_ok=True)
        subprocess.run(["ovs-vsctl", "--if-exists", "remove", "Open_vSwitch", ".",
                        "other_config", "flow-restore-wait"], check=True)

    elif TAKEOVER:
        with IPRoute() as ipr:
            if NIC_ENV:
                nic = NIC_ENV
            else:
                for route in ipr.get_default_routes(family=socket.AF_INET):
                    oif = route.get_attr("RTA_OIF")
                    if oif:
                        nic = ipr.link("get", index=oif)[0].get_attr("IFLA_IFNAME")
                        break
                else:
                    raise SystemExit("takeover: no default IPv4 route; set PUBLIC_INTERFACE")

            (link,) = ipr.link("get", ifname=nic)
            mac = link.get_attr("IFLA_ADDRESS")

            NETDIR.mkdir(parents=True, exist_ok=True)
            (NETDIR / "10-ovs-uplink.network").write_text(
                JINJA.get_template("ovs-uplink.network.j2").render(nic=nic))
            (NETDIR / f"15-{BR}.network").write_text(
                JINJA.get_template("ovs-bridge.network.j2").render(br=BR))

            # Shadow vendor .network files that match $NIC by symlinking their
            # basename in /etc to /dev/null.
            if VENDOR_DIR.is_dir():
                for vendor in sorted(VENDOR_DIR.glob("*.network")):
                    etc_path = NETDIR / vendor.name
                    # Leave admin-authored files alone.
                    if etc_path.exists() and not (etc_path.is_symlink()
                                                  and os.readlink(etc_path) == "/dev/null"):
                        continue
                    if vendor_matches(vendor, nic, mac):
                        etc_path.unlink(missing_ok=True)
                        etc_path.symlink_to("/dev/null")

            # Pin bridge to $NIC's MAC before add-port so upstream sees no L2 change.
            subprocess.run(["ovs-vsctl", "--may-exist", "add-br", BR], check=True)
            subprocess.run(["ovs-vsctl", "set", "bridge", BR, f"other-config:hwaddr={mac}"], check=True)
            ipr.link("set", index=ipr.link_lookup(ifname=BR)[0], address=mac)
            subprocess.run(["ovs-vsctl", "--may-exist", "add-port", BR, nic], check=True)

            # Reconfigure $BR before $NIC so resolved gains $BR's DNS before losing $NIC's.
            subprocess.run(NSENTER + ["networkctl", "reload"], check=True)
            subprocess.run(NSENTER + ["networkctl", "reconfigure", BR], check=True)
            for _ in range(30):
                addrs = ipr.get_addr(index=ipr.link_lookup(ifname=BR)[0], family=socket.AF_INET)
                if addrs:
                    br_ip = addrs[0].get_attr("IFA_ADDRESS")
                    break
                time.sleep(1)
            else:
                raise SystemExit(f"{BR} did not acquire DHCPv4 lease within 30s")

            # Converge upstream CAM tables onto the bridge port.
            subprocess.run(["arping", "-q", "-c", "2", "-U", "-I", BR, br_ip], check=False)
            subprocess.run(NSENTER + ["networkctl", "reconfigure", nic], check=True)

    sys.exit(ovs_proc.wait())
