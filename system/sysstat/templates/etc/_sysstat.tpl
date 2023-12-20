#!/usr/bin/env bash

dataInterval=300 # for how many seconds do we gather data
runInterval=60 # how often do we gather data

mkdir -p /host/var/log/sysstat-log

while true
do
  d=`date +%d-%m-%Y`
  sar -dubr -n ALL $dataInterval 1 -o /host/var/log/sysstat-log/${NODE_NAME}-sysstat-sar-$d.log
  sleep $runInterval
done
