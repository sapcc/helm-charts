#!/bin/bash

. /monasca-bin/common-start

if [ "$2" = "" ]; then
  echo "Usage: drop-dimension <tenant-id> <dimension>"
  exit 1
else
  tenant=$1
  dim=$2
fi

echo "Dropping all series using dimension ${dim} from tenant ${tenant}"
echo "Press Ctr-C to cancel within 10 secs ..."

sleep 10
squotes="'"
/usr/bin/influx -username mon_api -password {{.Values.monasca_influxdb_monapi_password}} -database mon -execute "show measurements where ${dim} != ''" | tail -n +4 | xargs -I %arg% /usr/bin/influx -username mon_api -password {{.Values.monasca_influxdb_monapi_password}} -database mon -execute "drop series from \"%arg%\" where (${dim} != '') AND (_tenant_id = ${squote}${tenant}${squote})"
