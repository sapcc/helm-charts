#!/bin/bash

#job to delete wrongly created indexes, which have timestamps in the future
export CLEANUP_INDEXES="logstash"

export LC_ALL=C.UTF-8; export LANG=C.UTF-8

export CLUSTER_HOST_BASE=$(echo ${CLUSTER_HOST} | sed -E 's|https://([^:/]+).*|\1|')

# Create a temporary netrc file
export NETRC_FILE=$(mktemp)
trap "rm -f ${NETRC_FILE}" EXIT

# Try first user
echo "machine ${CLUSTER_HOST_BASE} login ${ADMIN_USER} password ${ADMIN_PASSWORD}" > ${NETRC_FILE}
curl -s --netrc-file ${NETRC_FILE} ${CLUSTER_HOST}/
if [ $? -ne 0 ]; then
  echo "First user failed, trying second user"

  # Try second user
  echo "machine ${CLUSTER_HOST_BASE} login ${ADMIN2_USER} password ${ADMIN2_PASSWORD}" > ${NETRC_FILE}
  curl -s --netrc-file ${NETRC_FILE} ${CLUSTER_HOST}/
  if [ $? -ne 0 ]; then
    echo "Second user failed, giving up..."
    exit 1
  fi
fi

for i in ${CLEANUP_INDEXES}
do
  export TO_DELETE_NEAR_FUTURE=`curl -s --netrc-file ${NETRC_FILE} ${CLUSTER_HOST}/_aliases?pretty=true|grep $i | grep '20[0,1,3-9]'|awk '{ print $1}'|tr -d ':"'`
  for e in ${TO_DELETE_NEAR_FUTURE}
    do
      echo -e "Deleting index $e"
      curl --netrc-file ${NETRC_FILE} -X DELETE ${CLUSTER_HOST}/$e?pretty
  done
  export TO_DELETE_FUTURE=`curl -s --netrc-file ${NETRC_FILE} ${CLUSTER_HOST}/_aliases?pretty=true|grep $i | grep '2[1-9][0-9][0-9]'|awk '{ print $1}'|tr -d ':"'`
  for p in ${TO_DELETE_FUTURE}
    do
      echo -e "Deleting index $p"
      curl --netrc-file ${NETRC_FILE} -X DELETE ${CLUSTER_HOST}/$p?pretty
  done
  export TO_DELETE_PAST=`curl -s --netrc-file ${NETRC_FILE} ${CLUSTER_HOST}/_aliases?pretty=true|grep $i | grep '19[0-9][0-9]'|awk '{ print $1}'|tr -d ':"'`
  for d in ${TO_DELETE_FUTURE}
    do
      echo -e "Deleting index $d"
      curl --netrc-file ${NETRC_FILE} -X DELETE ${CLUSTER_HOST}/$d?pretty
  done
done
