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
export ALL_INDEXES=/all_indexes
export MISSING_ILM=/missing

# Get a list of all indexes and put it into a file, because we are working with too many indexes
for l in ${ILM_INDEXES}; do
  curl -s -k -u "admin:${ADMINPW}" -XGET "${CLUSTER_HOST}/_cat/indices"|grep ${i} |awk '{ print $3 }' >>$ALL_INDEXES
done

# Get a list of all indexes, which are not managed.
while read i; do
  export MANAGED_OR_NOT=$(curl -s -k -u "admin:${ADMINPW}" -XGET "${CLUSTER_HOST}/_plugins/_ism/explain/${i}"|jq .total_managed_indices)
  if [ "$MANAGED_OR_NOT" -eq "0" ]; then
     echo -e "\nIndex without a policy ${i}, appying ism policy\n"
     echo "${i}" >> ${MISSING_ILM}
  fi
done <${ALL_INDEXES}


export POLICY_RETURN_CODE=$( curl -s -o /dev/null -s -w "%{http_code}\n" -k -u "admin:${ADMINPW}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention")
echo -e "Return code is $POLICY_RETURN_CODE"
if [ "${POLICY_RETURN_CODE}" -eq 404 ]; then
  # 1. Part: install of new index policy
  echo -e "inital upload of index policy\n"
  echo -e "Upload index policy, there is no policy "${RETENTION_NAME}retention" installed"
  # upload ilm template
:76
  # no ilm template exists, applying this ilm template to indexes
Usage: grep [OPTION]... PATTERNS [FILE]...
Try 'grep --help' for more information.
+ read i
++ curl -s -o /dev/null -s -w '%{http_code}\n' -k -u admin:${ADMINPW} -XGET https://opensearch-hermes.hermes.svc.kubernetes.qa-de-1.cloud.sap:9200/_plugins/_ism/policies/auditerretention
+ export POLICY_RETURN_CODE=404
+ POLICY_RETURN_CODE=404
+ echo -e 'Return code is 404'
Return code is 404
+ '[' 404 -eq 404 ']'
+ echo -e 'inital upload of index policy\n'
inital upload of index policy

+ echo -e 'Upload index policy, there is no policy auditerretention installed'
Upload index policy, there is no policy auditerretention installed
+ curl -k -u admin:${ADMINPW} -XPUT https://opensearch-hermes.hermes.svc.kubernetes.qa-de-1.cloud.sap:9200/_plugins/_ism/policies/auditerretention -H 'Content-Type: application/json' -d @/scripts/ilm.json
{"error":{"root_cause":[{"type":"index_management_exception","reason":"New policy auditerretention has an ISM template with index pattern [audit-*] matching existing policy templates, please use a different priority than 1"}],"type":"index_management_exception","reason":"New policy auditerretention has an ISM template with index pattern [audit-*] matching existing policy templates, please use a different priority than 1","caused_by":{"type":"exception","reason":"java.lang.IllegalArgumentException: New policy auditerretention has an ISM template with index pattern [audit-*] matching existing policy templates, please use a different priority than 1"}},"status":400}+ read i
++ curl -s -k -u admin:${ADMINPW} -XGET https://opensearch-hermes.hermes.svc.kubernetes.qa-de-1.cloud.sap:9200/_plugins/_ism/policies/auditerretention
++ jq '._version?'
+ export CLUSTER_RETENTION_SCHEMA_VERSION=null
+ CLUSTER_RETENTION_SCHEMA_VERSION=null
+ echo -e '\n\n\nsecret file schema_version: '



secret file schema_version:
+ echo -e 'secret installed schema_version: null'
secret installed schema_version: null
+ '[' '' -gt null ']'
./install-index.sh: line 76: [: : integer expression expected
++ curl -s -k -u admin:${ADMINPW} -XGET https://opensearch-hermes.hermes.svc.kubernetes.qa-de-1.cloud.sap:9200/_plugins/_ism/policies/auditerretention
++ jq '._version?'
+ export NEW_CLUSTER_RETENTION_SCHEMA_VERSION=null
+ NEW_CLUSTER_RETENTION_SCHEMA_VERSION=null
+ echo -e '\nNew schema_version is: null\nIncrease this value by 1 to install new ism policy for auditerretention\n'

New schema_version is: null
Increase this value by 1 to install new ism policy for auditerretention

root@elasticdump-0:/scripts# vi install-index.sh
root@elasticdump-0:/scripts# cat install-index.sh
#!/bin/bash

set -x;

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
export ALL_INDEXES=/all_indexes
export MISSING_ILM=/missing

# Get a list of all indexes and put it into a file, because we are working with too many indexes
for l in ${ILM_INDEXES}; do
  curl -s -k -u "admin:${ADMINPW}" -XGET "${CLUSTER_HOST}/_cat/indices"|grep ${i} |awk '{ print $3 }' >>$ALL_INDEXES
done

# Get a list of all indexes, which are not managed.
while read i; do
  export MANAGED_OR_NOT=$(curl -s -k -u "admin:${ADMINPW}" -XGET "${CLUSTER_HOST}/_plugins/_ism/explain/${i}"|jq .total_managed_indices)
  if [ "$MANAGED_OR_NOT" -eq "0" ]; then
     echo -e "\nIndex without a policy ${i}, appying ism policy\n"
     echo "${i}" >> ${MISSING_ILM}
  fi
done <${ALL_INDEXES}


export POLICY_RETURN_CODE=$( curl -s -o /dev/null -s -w "%{http_code}\n" -k -u "admin:${ADMINPW}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention")
echo -e "Return code is $POLICY_RETURN_CODE"
if [ "${POLICY_RETURN_CODE}" -eq 404 ]; then
  # 1. Part: install of new index policy
  echo -e "inital upload of index policy\n"
  echo -e "Upload index policy, there is no policy "${RETENTION_NAME}retention" installed"
  # upload ilm template
  curl -k -u "admin:${ADMINPW}" -XPUT "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention" -H 'Content-Type: application/json' -d @${ILM_FILE};

  # no ilm template exists, applying this ilm template to indexes
  while read i; do
    export MANAGED_OR_NOT=$(curl -s -k -u "admin:${ADMINPW}" -XGET "${CLUSTER_HOST}/_plugins/_ism/explain/${i}"|jq .total_managed_indices)
    if [ "$MANAGED_OR_NOT" -eq "0" ]; then
      echo -e "\nIndex without a policy ${i}, appying ism policy\n"
      curl -H "Content-Type: application/json" --silent -k -u "admin:${ADMINPW}" -XPOST "${CLUSTER_HOST}/_plugins/_ism/add/${i}" -d @/scripts/add.json;
    fi
  done <${ALL_INDEXES}

elif [ "${POLICY_RETURN_CODE}" -eq 401 ]; then
  echo -e "Unauthorized, please check role for this user or wrong password password"
else
  echo -e "\nISM policy already exists, return code is ${POLICY_RETURN_CODE}\n";
  while read i; do
       echo -e "\nIndex without a policy ${i}, appying ism policy\n"
       curl -H "Content-Type: application/json" --silent -k -u "admin:${ADMINPW}" -XPOST "${CLUSTER_HOST}/_plugins/_ism/add/${i}" -d @/scripts/add.json;
  done <${MISSING_ILM}
fi

# 2. Part update of existing policy
# update of policy based on existing SEQ_NUMBER and PRIM_TERM, both have to be the same as the one, which is installed. Otherwise an update is not possible.
# Only update ism template, if schema_version has a new version number

export CLUSTER_RETENTION_SCHEMA_VERSION=$(curl -s -k -u "admin:${ADMINPW}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention"|jq ._version?)

echo -e "\n\n\nsecret file schema_version: ${FILE_RETENTION_SCHEMA_VERSION}"
echo -e "secret installed schema_version: ${CLUSTER_RETENTION_SCHEMA_VERSION}"


if [ "$FILE_RETENTION_SCHEMA_VERSION" -gt "$CLUSTER_RETENTION_SCHEMA_VERSION" ]; then
  export RUN_PRIM_TERM=$(curl -s -k -u "admin:${ADMINPW}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention" |jq ._primary_term)
  export RUN_SEQ_NUMBER=$(curl -s -k -u "admin:${ADMINPW}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention" |jq ._seq_no )
  echo -e "\nupload of new ism template with primary number: ${RUN_PRIM_TERM} and existing sequence number: ${RUN_SEQ_NUMBER}\n"
  curl -k -u "admin:${ADMINPW}" -XPUT "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention?if_seq_no=${RUN_SEQ_NUMBER}&if_primary_term=${RUN_PRIM_TERM}" -H 'Content-Type: application/json' -d @${ILM_FILE};

  # update all indexes with new policy
  while read i; do
      curl -H "Content-Type: application/json" --silent -k -u "admin:${ADMINPW}" -XPOST "${CLUSTER_HOST}/_plugins/_ism/add/${i}" -d @/scripts/add.json;
  done <${ALL_INDEXES}
fi

export NEW_CLUSTER_RETENTION_SCHEMA_VERSION=$(curl -s -k -u "admin:${ADMINPW}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/${RETENTION_NAME}retention"|jq ._version?)
echo -e "\nNew schema_version is: ${NEW_CLUSTER_RETENTION_SCHEMA_VERSION}\nIncrease this value by 1 to install new ism policy for ${RETENTION_NAME}retention\n"
