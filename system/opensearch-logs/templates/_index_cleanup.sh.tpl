#!/bin/bash

export HOST=https://opensearch-logs-client:9200
export CLEANUP_INDEXES="kubernikus virtual"

export LC_ALL=C.UTF-8; export LANG=C.UTF-8

for i in ${CLEANUP_INDEXES}
do
  curl --insecure -s -u "${ADMIN_USER}:${ADMIN_PW}" ${HOST}/_aliases?pretty=true|grep $i | grep '20[3-9]'|awk '{ print $1}'|tr -d '"'|xargs -I {} curl --insecure -u "${ADMIN_USER}:${ADMIN_PW}" -X DELETE ${HOST}/{}?pretty
  curl --insecure -s -u "${ADMIN_USER}:${ADMIN_PW}" ${HOST}/_aliases?pretty=true|grep $i | grep '2[1-9][0-9][1-9]'|awk '{ print $1}'|tr -d '"'|xargs -I {} curl --insecure -u "${ADMIN_USER}:${ADMIN_PW}" -X DELETE ${HOST}/{}?pretty
  curl --insecure -s -u "${ADMIN_USER}:${ADMIN_PW}" ${HOST}/_aliases?pretty=true|grep $i | grep '19[0-9][0-9]'|awk '{ print $1}'|tr -d '"'|xargs -I {} curl --insecure -u "${ADMIN_USER}:${ADMIN_PW}" -X DELETE ${HOST}/{}?pretty
done
