#!/bin/bash

# unset all proxy settings
unset http_proxy https_proxy no_proxy

# call this script to make sure that ceilometer-rabbitmq can be reached from within your container
MYCOUNT=0
MYMAXCOUNT=10
MYRABBITMQISRUNNING="false"
while [ "$MYCOUNT" != "$MYMAXCOUNT" ] && [ "$MYRABBITMQISRUNNING" = "false" ]; do
  echo "testing connection to ceilometer-rabbitmq:{{.Values.ceilometer_rabbitmq_port_mgmt}}"
  curl -m 30 -s http://guest:{{.Values.ceilometer_rabbitmq_default_pass}}@ceilometer-rabbitmq:{{.Values.ceilometer_rabbitmq_port_mgmt}}/api/aliveness-test/%2F | grep -q '"status":"ok"'
  if [ "$?" = "0" ]; then
    echo "ceilometer-rabbitmq server seems to be alive - will continue to startup"
    MYRABBITMQISRUNNING="true"
  else
    echo "no ceilometer-rabbitmq server found - will wait 10 more seconds with further startup"
  fi
  sleep 10
  MYCOUNT=$((MYCOUNT + 1))
done

if [ "$MYRABBITMQISRUNNING" = "false" ]; then
  echo "Startup failed - ceilometer-rabbitmq not available"
  exit 1
fi
