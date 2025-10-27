# neutron-rootwrap command filters for nodes on which neutron is
# expected to control network
#
# This file should be owned by (and only-writeable by) the root user

# format seems to be
# cmd-name: filter-name, raw-command, user, args

[Filters]

# dhcp-agent
dnsmasq: CommandFilter, dnsmasq, root
# dhcp-agent uses kill as well, that's handled by the generic KillFilter
# it looks like these are the only signals needed, per
# neutron/agent/linux/dhcp.py
kill_dnsmasq: KillFilter, root, /sbin/dnsmasq, -9, -HUP
kill_dnsmasq_usr: KillFilter, root, /usr/sbin/dnsmasq, -9, -HUP

ovs-vsctl: CommandFilter, ovs-vsctl, root
ivs-ctl: CommandFilter, ivs-ctl, root
mm-ctl: CommandFilter, mm-ctl, root
dhcp_release: CommandFilter, dhcp_release, root

# haproxy
haproxy: RegExpFilter, haproxy, root, haproxy, -f, .*
kill_haproxy: KillFilter, root, haproxy, -15, -9, -HUP
# DEPRECATED: metadata proxy
metadata_proxy: CommandFilter, neutron-ns-metadata-proxy, root

# TODO(dalvarez): Remove kill_metadata* filters in Q release since
# neutron-ns-metadata-proxy is now replaced by haproxy. We keep them for now
# for the migration process
# RHEL invocation of the metadata proxy will report /usr/bin/python
kill_metadata: KillFilter, root, python, -9
kill_metadata7: KillFilter, root, python2.7, -9
# SAPCC: for killing neutron-ns-metadata-proxy on CC
kill_metadata2: KillFilter, root, python2, -9

# ip_lib
ip: IpFilter, ip, root
find: RegExpFilter, find, root, find, /sys/class/net, -maxdepth, 1, -type, l, -printf, %.*
ip_exec: IpNetnsExecFilter, ip, root
