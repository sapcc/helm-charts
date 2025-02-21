#!/bin/bash

#job to delete wrongly created indexes, which have timestamps in the future
export CLUSTER_HOST=https://opensearch-logs-client.{{ .Values.global.clusterType}}.{{ .Values.global.region }}.{{ .Values.global.tld }}:9200
export CLEANUP_INDEXES="kubernikus virtual scaleout logstash"

export LC_ALL=C.UTF-8; export LANG=C.UTF-8

curl -s -u "${ADMIN_USER}:${ADMIN_PASSWORD}" ${CLUSTER_HOST}/
if [ $? -ne 0 ]; then
  echo "First user failed, trying second user"
  # Second attempt with user2 if user1 fails
  curl -s -u "${ADMIN2_USER}:${ADMIN2_PASSWORD}" ${CLUSTER_HOST}/
  if [ $? -ne 0 ]; then
    echo "Second user failed, giving up..."
    exit 1
  else
    export BASIC_AUTH_HEADER=${ADMIN2_USER}:${ADMIN2_PASSWORD}
  fi
else
  export BASIC_AUTH_HEADER=${ADMIN_USER}:${ADMIN_PASSWORD}
fi

for i in ${CLEANUP_INDEXES}
do
  export TO_DELETE_NEAR_FUTURE=`curl -s -u "${BASIC_AUTH_HEADER}" ${CLUSTER_HOST}/_aliases?pretty=true|grep $i | grep '20[0,1,3-9]'|awk '{ print $1}'|tr -d ':"'`
  for e in ${TO_DELETE_NEAR_FUTURE}
    do
      echo -e "Deleting index $e"
      curl -u "${BASIC_AUTH_HEADER}" -X DELETE ${CLUSTER_HOST}/$e?pretty
  done
  export TO_DELETE_FUTURE=`curl -s -u "${BASIC_AUTH_HEADER}" ${CLUSTER_HOST}/_aliases?pretty=true|grep $i | grep '2[1-9][0-9][0-9]'|awk '{ print $1}'|tr -d ':"'`
  for p in ${TO_DELETE_FUTURE}
    do
      echo -e "Deleting index $p"
      curl -u "${BASIC_AUTH_HEADER}" -X DELETE ${CLUSTER_HOST}/$p?pretty
  done
  export TO_DELETE_PAST=`curl -s -u "${BASIC_AUTH_HEADER}" ${CLUSTER_HOST}/_aliases?pretty=true|grep $i | grep '19[0-9][0-9]'|awk '{ print $1}'|tr -d ':"'`
  for d in ${TO_DELETE_FUTURE}
    do
      echo -e "Deleting index $d"
      curl -u "${BASIC_AUTH_HEADER}" -X DELETE ${CLUSTER_HOST}/$d?pretty
  done
done
