#!/bin/bash

#set -x;

# simple script to update ism/ilm index policy.
# Important steps:
# Two values retrieved from the database have to be set to upload an ism index policy
# PRIM_TERM and SEQ_NUMBER have to be retrieved and used during upload.
# To not upload the template everytime we set a version number in the secrets and compare this value with
# the _version number of an installed index template (auto incremented by the database).
#
# This script is used for OpenSearch Hermes and logs, because of different requirements and settings there are if
# sections for Hermes and logs.
#
# After a new index template is installed the new index template is assigned to all existing indexes, which are listed in  the secrets variable ism_indexes.

echo -e "0. Check for index policy\n"

export ILM_FILE=/scripts/ilm.json

export POLICY_RETURN_CODE=$( curl -s -o /dev/null -s -w "%{http_code}\n" --insecure -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention")
echo -e "Return code is $POLICY_RETURN_CODE"
if [ "${POLICY_RETURN_CODE}" -eq 404 ]; then
  # 1. Part: install of new index policy
  echo -e "inital upload of index policy\n"
  echo -e "Upload index policy, there is no policy "${RETENTION_NAME}retention" installed"
  curl --insecure -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XPUT "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention" -H 'Content-Type: application/json' -d @${ILM_FILE}

  # add all indexes, which need a retention
  echo "\nManaged indexes are ${ILM_INDEXES}\n"

  # get all indexes without a policy
  export MISSING_INDEXES=$(for l in ${ILM_INDEXES}; do    curl -s --insecure -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XGET --insecure "${CLUSTER_HOST}/_plugins/_ism/explain/${l}-*"|jq|grep -B4 "enabled\": null"|grep ${l}|awk -F: '{ print $1}'|awk -F\" '{ print $2}'; done)
  if [ -z "$MISSING_INDEXES" ]; then
    echo -e "\nNo index without policy\n";
  else
for i in ${MISSING_INDEXES}
do
  echo -e "\nindex without a policy ${i}, appying ism policy\n"
  curl --header 'content-type: application/JSON' --silent --insecure -u "${ADMIN_USER}:${ADMIN_PASSWORD}" --insecure -XPOST "${CLUSTER_HOST}/_plugins/_ism/add/${i}" -d "{ \"policy_id\": \"${RETENTION_NAME}retention\" }"
done;
  fi;
elif [ "${POLICY_RETURN_CODE}" -eq 401 ]; then
  echo -e "Unauthorized, please check roles for user or password"
else
  echo -e "\nISM policy already exists, return code is ${POLICY_RETURN_CODE}\n";
  # get all indexes without a policy
  export MISSING_INDEXES=$(for l in ${ILM_INDEXES}; do    curl -s --insecure -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XGET --insecure "${CLUSTER_HOST}/_plugins/_ism/explain/${l}-*"|jq|grep -B4 "enabled\": null"|grep ${l}|awk -F: '{ print $1}'|awk -F\" '{ print $2}'; done)
  if [ -z "$MISSING_INDEXES" ]; then
    echo -e "\nNo index without policy\n";
  else
for i in ${MISSING_INDEXES}
do
  echo -e "\nindex without a policy ${i}, appying ism policy\n"
  curl --header 'content-type: application/JSON' --silent --insecure -u "${ADMIN_USER}:${ADMIN_PASSWORD}" --insecure -XPOST "${CLUSTER_HOST}/_plugins/_ism/add/${i}" -d "{ \"policy_id\": \"${RETENTION_NAME}retention\" }"
done;
  fi;
fi

# 2. Part update of existing policy
# update of policy based on existing SEQ_NUMBER and PRIM_TERM, both have to be the same as the one, which is installed. Otherwise an update is not possible.
# Only update ism template, if schema_version has a new version number

export CLUSTER_RETENTION_SCHEMA_VERSION=$(curl -s --insecure -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XGET --insecure "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention"|jq ._version?)

echo -e "secret file schema_version: ${FILE_RETENTION_SCHEMA_VERSION}"
echo -e "secret installed schema_version: ${CLUSTER_RETENTION_SCHEMA_VERSION}"


if [ "$FILE_RETENTION_SCHEMA_VERSION" -gt "$CLUSTER_RETENTION_SCHEMA_VERSION" ]; then
  export RUN_PRIM_TERM=$(curl -s --insecure -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XGET --insecure "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention" |jq ._primary_term)
  export RUN_SEQ_NUMBER=$(curl -s --insecure -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XGET --insecure "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention" |jq ._seq_no )
  echo -e "\nupload of new ism template with primary number: ${RUN_PRIM_TERM} and existing sequence number: ${RUN_SEQ_NUMBER}\n"
  curl --insecure -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XPUT "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention?if_seq_no=${RUN_SEQ_NUMBER}&if_primary_term=${RUN_PRIM_TERM}" -H 'Content-Type: application/json' -d @${ILM_FILE};

  # update all indexes with new policy
  export UPDATE_INDEXES=$(for l in ${ILM_INDEXES}; do curl -s --insecure -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XGET --insecure "${CLUSTER_HOST}/_cat/indices?v"|grep ${l}|awk '{ print $3 }'  ; done)
  for e in ${UPDATE_INDEXES}; do
     echo -e "\nAssigning new ism policy version to index: ${e}\n"
     curl --insecure -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -H 'Content-Type: application/json' -XPOST "${CLUSTER_HOST}/_plugins/_ism/change_policy/${e}" -d "{ \"policy_id\": \"${RETENTION_NAME}retention\" }"
  done;
fi

export NEW_CLUSTER_RETENTION_SCHEMA_VERSION=$(curl -s --insecure -u "${ADMIN_USER}:${ADMIN_PASSWORD}" -XGET --insecure "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention"|jq ._version?)
echo -e "\nNew schema_version is: ${NEW_CLUSTER_RETENTION_SCHEMA_VERSION}\n, increase this value by 1 to install new ism policy for ${RETENTION_NAME}etention\n"
