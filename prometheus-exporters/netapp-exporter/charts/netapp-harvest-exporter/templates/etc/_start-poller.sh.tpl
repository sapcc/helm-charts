#!/bin/bash
netappsd_url=$1
shift
replica_hash=${HOSTNAME%-*}
replica_hash=${replica_hash##*-}

echo "fetch config from $netappsd_url/harvest.yml"
filer=""
lastcode=""
while [ -z "$filer" ]; do
  code=$(wget --post-data "{\"hash\": \"$replica_hash\"}" --header "content-type: application/json" --server-response -O harvest.yml $netappsd_url/next/harvest.yaml 2>&1 | grep "HTTP/" | awk '{print $2}')
  if [ "$code" -eq "200" ]; then
    filer=$(grep 'stnpca.*:' harvest.yml | cut -d: -f1 | awk '{print $1}')
    break
  else
    if [ "$code" != "$lastcode" ]; then
      echo "failed to fetch harvest.yml: $code"
      lastcode=$code
    fi
  fi
  sleep 60
done
echo "start harvest poller $filer on port $1"
exec bin/poller --poller $filer --promPort $1 --loglevel {{ .Values.harvest.loglevel }}
