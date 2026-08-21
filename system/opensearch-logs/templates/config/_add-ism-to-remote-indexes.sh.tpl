#!/bin/bash

export CLUSTER_HOST_BASE=$(echo ${CLUSTER_HOST} | sed -E 's|https://([^:/]+).*|\1|')

# Create a temporary netrc file
export NETRC_FILE=$(mktemp)
trap "rm -f ${NETRC_FILE}" EXIT

####
### Check which admin user is active
####
echo "machine ${CLUSTER_HOST_BASE} login ${ADMIN_USER} password ${ADMIN_PASSWORD}" > "${NETRC_FILE}"
curl -s --netrc-file "${NETRC_FILE}" "${CLUSTER_HOST}/"
if [ $? -ne 0 ]; then
  echo "First user failed, trying second user"
  # Second attempt with user2 if user1 fails
  echo "machine ${CLUSTER_HOST_BASE} login ${ADMIN2_USER} password ${ADMIN2_PASSWORD}" > "${NETRC_FILE}"
  curl -s --netrc-file "${NETRC_FILE}" "${CLUSTER_HOST}/"
  if [ $? -ne 0 ]; then
    echo "Second user failed, giving up..."
    exit 1
  fi
fi

####
### Remote ISM policy verification and attachment
####
for e in ${DATA_STREAMS}; do
  export FILEPATH=/scripts
  export TMPPATH=/tmp

  export REMOTE_INDEXES_RESPONSE=${TMPPATH}/remote-${e}-indexes.json
  curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/remote_.ds-${e}-datastream*?expand_wildcards=all" -o ${REMOTE_INDEXES_RESPONSE}
  export NUMBER_OF_REMOTE_INDEXES=$(jq 'keys | length' ${REMOTE_INDEXES_RESPONSE})
  echo "Number of remote indexes for ${e} datastream: ${NUMBER_OF_REMOTE_INDEXES}"

  if [ "${NUMBER_OF_REMOTE_INDEXES}" -gt 0 ]; then
    export POLICY_RETURN_CODE=$( curl -s -o /dev/null -s -w "%{http_code}\n" --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/remote-${e}-ism")
    if [ "${POLICY_RETURN_CODE}" -ne 200 ]; then
      echo "ISM policy remote-${e}-ism does not exist (HTTP code: ${POLICY_RETURN_CODE}). Skipping attachment for remotes for ${e}."
      continue
    fi

    export REMOTE_INDEX_NAMES=$(jq -r 'keys[]' ${REMOTE_INDEXES_RESPONSE})
    for idx in ${REMOTE_INDEX_NAMES}; do
    export EXPLAIN_RESPONSE=${TMPPATH}/remote-${e}-idx-explain.json
    curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_ism/explain/${idx}" -o ${EXPLAIN_RESPONSE}
    export TOTAL_MANAGED_INDICES=$(jq '.total_managed_indices' ${EXPLAIN_RESPONSE})
    export ASSIGNED_POLICY=$(jq -r '.[] | select(type == "object" and has("index.plugins.index_state_management.policy_id")) | .["index.plugins.index_state_management.policy_id"]' ${EXPLAIN_RESPONSE})
    if [ "${TOTAL_MANAGED_INDICES}" -eq 0 ]; then
      echo "Index ${idx} has no ism policy"
      echo "Assigning remote-${e}-ism to ${idx} index"
      curl --header 'content-type: application/JSON' --netrc-file "${NETRC_FILE}" -XPOST "${CLUSTER_HOST}/_plugins/_ism/add/${idx}" -d "{ \"policy_id\": \"remote-${e}-ism\" }"
    else
      echo "${idx} is already managed by ${ASSIGNED_POLICY} policy"
    fi
  done
  fi

done
