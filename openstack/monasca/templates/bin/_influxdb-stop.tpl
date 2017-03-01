#!/bin/bash

echo "Safely shutting down InfluxDB" > /var/lib/influxdb/prestop.output
datestamp=$(date --utc --iso-8601=seconds)
now_secs=$(date --utc +%s) >> /var/lib/influxdb/prestop.output
if [ -e /var/lib/influxdb/snapshot.tstmp ]; then
  since_opt="-since $(cat /var/lib/influxdb/snapshot.tstmp)"
fi

filename=/var/lib/influxdb/snapshot-$datestamp
echo "Creating incremental backup to $filename" >> /var/lib/influxdb/prestop.output
/usr/bin/influxd backup -database mon $since_opt $filename
# replace timestamp, so that the next backup is incremental
echo "$datestamp" > /var/lib/influxdb/snapshot.tstmp 

# cleanup old data
for snapshot in $(ls /var/lib/influxdb/ | grep "snapshot-20"); do
  ts=$(date --utc --date=$(echo "$snapshot" | sed "s/snapshot-//") +%s)
  if [ $(($now_secs - $ts)) -gt $(({{.Values.monasca_influxdb_retention_days}} * 86400)) ]; then
    echo "  cleaning up $snapshot" >> /var/lib/influxdb/prestop.output
    rm -rf /var/lib/influxdb/$snapshot >> /var/lib/influxdb/prestop.output
  fi
done

# stop InfluxDB (since it ignores SIGTERM)
# TODO (below does not work anymore)
#CONFIG_FILE="/monasca-etc/influxdb-influxdb.conf"
#MONASCA_INFLUXDB_COMMAND='/usr/bin/influxd'
#$MONASCA_INFLUXDB_COMMAND stop -config=${CONFIG_FILE}
