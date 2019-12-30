#!/usr/bin/env bash

interface=( {{ required ".Values.pmtud.interface is required" .Values.pmtud.interface }} )
nflog_group=( {{ .Values.iptables.nflogGroup }} )
ignore_network=( {{ .Values.iptables.ignoreSourceNetwork }} )

if iptables -t raw -C PREROUTING -i ${interface} ! -s ${ignore_network} -p icmp -m icmp --icmp-type 3/4 --j NFLOG --nflog-group ${nflog_group} ; then
  echo "Rule already present - skipping"
else
  echo "Rule not present - creating rule"
  iptables -t raw -I PREROUTING -i ${interface} ! -s ${ignore_network} -p icmp -m icmp --icmp-type 3/4 --j NFLOG --nflog-group ${nflog_group}
fi
