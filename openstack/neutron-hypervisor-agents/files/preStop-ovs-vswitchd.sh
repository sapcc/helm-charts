#!/bin/sh
# preStop hook for ovs-vswitchd: preserve OpenFlow flow tables so the next
# ovs-vswitchd can restart hitlessly.
#
# ovs-save save-flows dumps flows to a shell script that re-installs them
# via ovs-ofctl replace-flows. ovs-appctl exit --cleanup=false shuts down
# ovs-vswitchd without touching the kernel datapath, so existing flows in
# the kernel keep forwarding through the userspace gap.
set -eu

bridges="$(ovs-vsctl --no-heading --columns=name list Bridge | tr -d '"')"
if [ -n "$bridges" ]; then
    /usr/share/openvswitch/scripts/ovs-save save-flows $bridges \
        > /run/openvswitch/saved-flows.sh
    chmod +x /run/openvswitch/saved-flows.sh
fi

ovs-appctl -t ovs-vswitchd exit --cleanup=false
