#!/bin/bash

#job to delete wrongly created indexes, which have timestamps in the future
export HOST=https://opensearch-logs-client.{{ .Values.global.clusterType}}.{{ .Values.global.region }}.{{ .Values.global.tld }}:9200
export CLEANUP_INDEXES="kubernikus virtual scaleout"

export LC_ALL=C.UTF-8; export LANG=C.UTF-8

for i in ${CLEANUP_INDEXES}
do
  export TO_DELETE_NEAR_FUTURE=`curl -s -u "${ADMIN_USER}:${ADMIN_PASSWORD}" ${HOST}/_aliases?pretty=true|grep $i | grep '20[0,1,3-9]'|awk '{ print $1}'|tr -d '"'`
  for e in ${TO_DELETE_NEAR_FUTURE}
    do
      echo -e "Deleting index $e"
      curl -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -X DELETE ${HOST}/$e?pretty
  done
  export TO_DELETE_FUTURE=`curl -s -u "${ADMIN_USER}:${ADMIN_PASSWORD}" ${HOST}/_aliases?pretty=true|grep $i | grep '2[1-9][0-9][0-9]'|awk '{ print $1}'|tr -d '"'`
  for p in ${TO_DELETE_FUTURE}
    do
      echo -e "Deleting index $p"
      curl -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -X DELETE ${HOST}/$p?pretty
  done
  export TO_DELETE_PAST=`curl -s -u "${ADMIN_USER}:${ADMIN_PASSWORD}" ${HOST}/_aliases?pretty=true|grep $i | grep '19[0-9][0-9]'|awk '{ print $1}'|tr -d '"'`
  for d in ${TO_DELETE_FUTURE}
    do
      echo -e "Deleting index $d"
      curl -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -X DELETE ${HOST}/$d?pretty
  done
done
