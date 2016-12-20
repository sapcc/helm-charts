{{- define "influxdb_setup_tpl" -}}
#!/bin/bash

API_URL="http://localhost:{{.Values.monasca_influxdb_port_internal}}"

#wait for the startup of influxdb
RET=1
while [ $RET -ne 0 ]; do
   echo "Waiting for confirmation of InfluxDB service startup ..."
   sleep 3
   curl -k ${API_URL}/ping 2> /dev/null
   RET=$?
done

# create cluster administrator
root_user_created=$(curl -s -G -q -o /dev/null -w %{http_code} "${API_URL}/query?" --data-urlencode "q=CREATE USER root WITH PASSWORD '{{.Values.monasca_influxdb_root_password}}' WITH ALL PRIVILEGES")
if [ $root_user_created != 200 ]; then
  root_user_created=$(curl -s -G -q -o /dev/null -w %{http_code} "${API_URL}/query?" -u root:{{.Values.monasca_influxdb_root_password}} --data-urlencode "q=CREATE USER root WITH PASSWORD '{{.Values.monasca_influxdb_root_password}}' WITH ALL PRIVILEGES")
  if [ $root_user_created != 200 ]; then
    echo "Cluster administrator 'root' could not be created: $root_user_created"
    exit 1
  fi
fi

# create cluster administrator
monitoring_user_created=$(curl -s -G -q -o /dev/null -w %{http_code} "${API_URL}/query?" -u root:{{.Values.monasca_influxdb_root_password}} --data-urlencode "q=CREATE USER monitoring WITH PASSWORD '{{.Values.monasca_influxdb_monitoring_password}}' WITH ALL PRIVILEGES")
if [ $monitoring_user_created != 200 ]; then
  echo "Cluster self-monitoring 'monitoring' could not be created: $monitoring_user_created"
  exit 1
fi

# now create monasca specific database
db_created=$(curl -s -q -o /dev/null -w %{http_code} -G "${API_URL}/query?" -u root:{{.Values.monasca_influxdb_root_password}} --data-urlencode "q=CREATE DATABASE IF NOT EXISTS mon WITH DURATION {{.Values.monasca_influxdb_retention_days}}d REPLICATION 1 NAME monasca")
if [ $db_created != 200 ]; then
  echo "Database could not be created: $db_created"
  exit 1
fi

mon_api_user_created=$(curl -s -G -q -o /dev/null -w %{http_code} "${API_URL}/query?" -u root:{{.Values.monasca_influxdb_root_password}} --data-urlencode "q=CREATE USER mon_api WITH PASSWORD '{{.Values.monasca_influxdb_monapi_password}}'; GRANT ALL ON mon TO mon_api")
if [ $mon_api_user_created != 200 ]; then
  echo "Database user 'mon_api' could not be created: $mon_api_user_created"
  exit 1
fi

mon_persister_user_created=$(curl -s -G -q -o /dev/null -w %{http_code} "${API_URL}/query?" -u root:{{.Values.monasca_influxdb_root_password}} --data-urlencode "q=CREATE USER mon_persister WITH PASSWORD '{{.Values.monasca_influxdb_monpersister_password}}'; GRANT WRITE ON mon TO mon_persister")
if [ $mon_persister_user_created != 200 ]; then
  echo "Database user 'mon_persister' could not be created: $mon_persister_user_created"
  exit 1
fi

# successful
echo "Monasca environment successfully prepared"
date --utc > ${MONASCA_INFLUXDB_PREP_FILE}
{{ end }}
