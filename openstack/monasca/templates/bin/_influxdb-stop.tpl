#!/bin/bash

echo "Safely shutting down InfluxDB" > /var/opt/influxdb/prestop.output
datestamp=$(date --utc --iso-8601=seconds)
now_secs=$(date --utc +%s) >> /var/opt/influxdb/prestop.output
if [ -e /var/opt/influxdb/snapshot.tstmp ]; then
  since_opt="-since $(cat /var/opt/influxdb/snapshot.tstmp)"
fi

filename=/var/opt/influxdb/snapshot-$datestamp
echo "Creating incremental backup to $filename" >> /var/opt/influxdb/prestop.output
/usr/bin/influxd backup -database mon $since_opt $filename
# replace timestamp, so that the next backup is incremental
echo "$datestamp" > /var/opt/influxdb/snapshot.tstmp 

# cleanup old data
for snapshot in $(ls /var/opt/influxdb/ | grep "snapshot-20"); do
  ts=$(date --utc --date=$(echo "$snapshot" | sed "s/snapshot-//") +%s)
  if [ $(($now_secs - $ts)) -gt $(({{.Values.monasca_influxdb_retention_days}} * 86400)) ]; then
    echo "  cleaning up $snapshot" >> /var/opt/influxdb/prestop.output
    rm -rf /var/opt/influxdb/$snapshot >> /var/opt/influxdb/prestop.output
  fi
done

# stop InfluxDB (since it ignores SIGTERM)
# TODO (below does not work anymore)
#CONFIG_FILE="/monasca-etc/influxdb-influxdb.conf"
#MONASCA_INFLUXDB_COMMAND='/usr/bin/influxd'
#$MONASCA_INFLUXDB_COMMAND stop -config=${CONFIG_FILE}
