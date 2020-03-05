#!/bin/bash

# This plugin checks if bridged vlan-tagged ARP/IP traffic was passed to arptables/iptables.

OK=0
NOTOK=1
UNKNOWN=2

[[ -f /host/proc/sys/net/bridge/bridge-nf-filter-vlan-tagged ]] || exit $UNKNOWN

result=$(cat /host/proc/sys/net/bridge/bridge-nf-filter-vlan-tagged)

if [[ $result -ne 0 ]]; then
    echo "Bridged VLAN-tagged traffic is not filtered by IPtables"
    exit $NOTOK
fi

echo "Bridged VLAN-tagged traffic is filtered by IPtables"
exit $OK
