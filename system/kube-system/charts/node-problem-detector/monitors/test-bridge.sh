#!/bin/bash

# This plugin checks if bridged vlan-tagged ARP/IP traffic was passed to arptables/iptables.

OK=0
NOTOK=1
UNKNOWN=2

[[ -f /host/proc/sys/net/bridge/bridge-nf-filter-vlan-tagged ]] || exit $UNKNOWN

result=$(cat /host/proc/sys/net/bridge/bridge-nf-filter-vlan-tagged)

if [[ $result -ne 0 ]]; then
    echo "VLAN tagged traffic was passed to arptables/iptables"
    exit $NOTOK
fi

exit $OK
