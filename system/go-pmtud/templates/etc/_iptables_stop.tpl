#!/usr/bin/env bash

# make sure to update iptables-init script to keep commands aligned

nflog_group=( {{ .Values.iptables.nflogGroup }} )
INTERFACE=$(/sbin/ip route | grep -v cbr | awk '/default/ { print $5 }')

echo "Outgoing inteface is ${INTERFACE}"

echo "Deleting rule for redirecting ICMP frag-needed packets to nflog-group ${nflog_group}"
iptables-nft -t raw -D PREROUTING -i ${INTERFACE} -p icmp -m icmp --icmp-type 3/4 --j NFLOG --nflog-group ${nflog_group}
