#!/bin/bash

. /monasca-bin/common-start

if [ "$2" = "" ]; then
  echo "Usage: drop-metric <tenant-id> <metric-regex>"
  exit 1
else
  tenant=$1
  metric=$2
fi

echo "Dropping all measurements matching ${metric} from tenant ${tenant}"
echo "Press Ctr-C to cancel within 10 secs ..."

sleep 10
squote="'"
/usr/bin/influx -username mon_api -password {{.Values.monasca_influxdb_monapi_password}} -database mon -execute "show measurements with measurement =~ ${metric}" | tail -n +4 | xargs -I %arg% /usr/bin/influx -username mon_api -password {{.Values.monasca_influxdb_monapi_password}} -database mon -execute "drop series from \"%arg%\" where _tenant_id = ${squote}${tenant_id}${squote}"
