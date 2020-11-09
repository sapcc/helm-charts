#!/usr/bin/env bash

# make sure to update iptables-stop script to keep commands aligned

nflog_group=( {{ .Values.iptables.nflogGroup }} )
INTERFACE=$(/sbin/ip route | grep -v cbr | awk '/default/ { print $5 }')

echo "Outgoing inteface is ${INTERFACE}"

{{- range $network := .Values.iptables.ignoreSourceNetworks }}
if iptables -t raw -C PREROUTING -i ${INTERFACE} ! -s {{ $network }} -p icmp -m icmp --icmp-type 3/4 --j NFLOG --nflog-group ${nflog_group} ; then
  echo "Rule for {{ $network }} already present - skipping"
else
  echo "Rule for {{ $network }} not present - creating rule"
  iptables -t raw -I PREROUTING -i ${INTERFACE} ! -s {{ $network }} -p icmp -m icmp --icmp-type 3/4 --j NFLOG --nflog-group ${nflog_group}
fi
{{- end }}