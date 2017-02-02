#!/bin/bash

# set some env variables from the openstack env properly based on env
. /monasca-bin/common-start

function process_config {
  export CONFIG_FILE="/monasca-etc/influxdb-influxdb.conf"
  export MONASCA_INFLUXDB_PREP_FILE="/var/opt/influxdb/cfg-influxdb.tstamp"
  MONASCA_INFLUXDB_COMMAND='/usr/bin/influxd'

  if [ ! -e $MONASCA_INFLUXDB_PREP_FILE ]; then
    echo "------------------------------------------------------------------------------"
    echo "Fresh InfluxDB installation detected (no data). Preparing for use with Monasca"
    echo "------------------------------------------------------------------------------"
    $MONASCA_INFLUXDB_COMMAND -config=${CONFIG_FILE} &
    sleep 10
    # initialize InfluxDB (this will create the prep.file) 
    /bin/bash /monasca-bin/influxdb-setup
    echo "-------------------------------------------------------------"
    echo "Shutting down InfluxDB to restart with enabled authentication"
    echo "-------------------------------------------------------------"
    exit 1
  fi
}

process_config

