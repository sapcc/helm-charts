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
### Remote ISM policy reation
####
for e in ${DATA_STREAMS}; do
  export FILEPATH=/scripts
  export TMPPATH=/tmp
  export ISM_TEMPLATE=remote-${e}-ism.json

  if [ ! -f "${FILEPATH}/${ISM_TEMPLATE}" ]; then
    echo "${FILEPATH}/${ISM_TEMPLATE} not defined. Skipping."
    continue
  fi

  echo "Applying ${TMPPATH}/${ISM_TEMPLATE} to the cluster"
  cp "${FILEPATH}/${ISM_TEMPLATE}" "${TMPPATH}/${ISM_TEMPLATE}"

  export POLICY_RETURN_CODE=$( curl -s -o /dev/null -s -w "%{http_code}\n" --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/remote-${e}-ism")
  echo -e "\nReturn code is $POLICY_RETURN_CODE\n"

  if [ "${POLICY_RETURN_CODE}" -eq 404 ]; then
    echo -e "Inital upload of remote ism policy"
    echo -e "Upload remote policy, there is no policy \"remote-${e}-ism\" installed"
    curl --netrc-file "${NETRC_FILE}" -XPUT "${CLUSTER_HOST}/_plugins/_ism/policies/remote-${e}-ism" -H 'Content-Type: application/json' -d @"${TMPPATH}/${ISM_TEMPLATE}"
    if [ $? -ne 0 ]; then
      echo "Failed to upload ${TMPPATH}/${ISM_TEMPLATE}!"
      exit 1
    fi
  else
    # update of existing policy
    # update of policy based on existing SEQ_NUMBER and PRIM_TERM, both have to be the same as the one, which is installed. Otherwise an update is not possible.
    # Only update ism template, if schema_version has a new version number
    export CLUSTER_RETENTION_RESPONSE=$(curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/remote-${e}-ism")
    export CLUSTER_RETENTION_SCHEMA_VERSION=$(echo ${CLUSTER_RETENTION_RESPONSE} | jq .policy.schema_version?)
    export CLUSTER_RETENTION_RUN_PRIM_TERM=$(echo ${CLUSTER_RETENTION_RESPONSE} | jq ._primary_term?)
    export CLUSTER_RETENTION_SEQ_NUMBER=$(echo ${CLUSTER_RETENTION_RESPONSE} | jq ._seq_no?)

    if [ -z "${FILE_SCHEMA_VERSION}" ]; then
       echo -e "Variable FILE_SCHEMA_VERSION is empty or not existing\n"
    else
      echo -e "secret env variable schema_version: ${FILE_SCHEMA_VERSION}"
    fi
    if [ -z "${CLUSTER_RETENTION_SCHEMA_VERSION}" ]; then
      echo -e "variable CLUSTER_RETENTION_SCHEMA_VERSION is empty or not existing\n"
    else
      echo "secret database schema_version: ${CLUSTER_RETENTION_SCHEMA_VERSION}"
    fi

    if [ "${FILE_SCHEMA_VERSION}" -gt "${CLUSTER_RETENTION_SCHEMA_VERSION}" ]; then
      echo -e "\nUpload of new ism template with primary number: ${CLUSTER_RETENTION_RUN_PRIM_TERM} and existing sequence number: ${CLUSTER_RETENTION_SEQ_NUMBER}\n"
      curl --netrc-file "${NETRC_FILE}" -XPUT "${CLUSTER_HOST}/_plugins/_ism/policies/remote-${e}-ism?if_seq_no=${CLUSTER_RETENTION_SEQ_NUMBER}&if_primary_term=${CLUSTER_RETENTION_RUN_PRIM_TERM}" -H 'Content-Type: application/json' -d @"${TMPPATH}/${ISM_TEMPLATE}"
      if [ $? -ne 0 ]; then
        echo "Failed to upload ${TMPPATH}/${ISM_TEMPLATE}!"
        exit 1
      fi
      cat "${TMPPATH}/${ISM_TEMPLATE}"
      export NEW_CLUSTER_RETENTION_SCHEMA_VERSION=$(curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/remote-${e}-ism"|jq .policy.schema_version?)
      echo -e "\nNew schema_version is: ${NEW_CLUSTER_RETENTION_SCHEMA_VERSION}\n, increase this value by 1 to install new ism policy for remote-${e}-ism\n" 
    else
      echo "No changes, ism template is not updated. Increase the version number to upload a new ism template"
    fi
  fi

done

####
### Remote ISM policy verification and attachment
####
for e in ${DATA_STREAMS}; do
  export FILEPATH=/scripts
  export TMPPATH=/tmp

  export REMOTE_INDEXES_RESPONSE=${TMPPATH}/remote-${e}-indexes.json
  curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/remote_.ds-${e}-datastream*?expand_wildcards=all" -o ${REMOTE_INDEXES_RESPONSE}
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

done

####
### Snapshot delete-only policy creation
####
for e in ${DATA_STREAMS}; do
  export FILEPATH=/scripts
  export TMPPATH=/tmp
  export SM_TEMPLATE=snapshot-${e}-delete-policy.json

  if [ ! -f "${FILEPATH}/${SM_TEMPLATE}" ]; then
    echo "${FILEPATH}/${SM_TEMPLATE} not defined. Skipping."
    continue
  fi

  echo "Applying ${TMPPATH}/${SM_TEMPLATE} to the cluster"
  cp "${FILEPATH}/${SM_TEMPLATE}" "${TMPPATH}/${SM_TEMPLATE}"

  export POLICY_RETURN_CODE=$( curl -s -o /dev/null -s -w "%{http_code}\n" --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_sm/policies/snapshot-${e}-delete-policy")
  echo -e "\nReturn code is $POLICY_RETURN_CODE\n"
  if [ "${POLICY_RETURN_CODE}" -eq 404 ]; then
    echo -e "Inital upload of delete-only sm policy"
    echo -e "Upload sm policy, there is no policy \"snapshot-${e}-delete-policy\" installed"
    curl --netrc-file "${NETRC_FILE}" -XPOST "${CLUSTER_HOST}/_plugins/_sm/policies/snapshot-${e}-delete-policy" -H 'Content-Type: application/json' -d @"${TMPPATH}/${SM_TEMPLATE}"
    if [ $? -ne 0 ]; then
      echo "Failed to upload ${TMPPATH}/${SM_TEMPLATE}!"
      exit 1
    fi
  else
    # update of existing policy
    # update of policy based on existing SEQ_NUMBER and PRIM_TERM, both have to be the same as the one, which is installed. Otherwise an update is not possible.
    # Only update ism template, if schema_version has a new version number
    export CLUSTER_RETENTION_RESPONSE=$(curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_sm/policies/snapshot-${e}-delete-policy")
    export CLUSTER_RETENTION_SCHEMA_VERSION=$(echo ${CLUSTER_RETENTION_RESPONSE} | jq .sm_policy.schema_version?)
    export CLUSTER_RETENTION_RUN_PRIM_TERM=$(echo ${CLUSTER_RETENTION_RESPONSE} | jq ._primary_term?)
    export CLUSTER_RETENTION_SEQ_NUMBER=$(echo ${CLUSTER_RETENTION_RESPONSE} | jq ._seq_no?)

    if [ -z "${FILE_SCHEMA_VERSION}" ]; then
       echo -e "Variable FILE_SCHEMA_VERSION is empty or not existing\n"
    else
      echo -e "secret env variable schema_version: ${FILE_SCHEMA_VERSION}"
    fi
    if [ -z "${CLUSTER_RETENTION_SCHEMA_VERSION}" ]; then
      echo -e "variable CLUSTER_RETENTION_SCHEMA_VERSION is empty or not existing\n"
    else
      echo "secret database schema_version: ${CLUSTER_RETENTION_SCHEMA_VERSION}"
    fi

    if [ "${FILE_SCHEMA_VERSION}" -gt "${CLUSTER_RETENTION_SCHEMA_VERSION}" ]; then
      echo -e "\nUpload of new sm template with primary number: ${CLUSTER_RETENTION_RUN_PRIM_TERM} and existing sequence number: ${CLUSTER_RETENTION_SEQ_NUMBER}\n"
      curl --netrc-file "${NETRC_FILE}" -XPUT "${CLUSTER_HOST}/_plugins/_sm/policies/snapshot-${e}-delete-policy?if_seq_no=${CLUSTER_RETENTION_SEQ_NUMBER}&if_primary_term=${CLUSTER_RETENTION_RUN_PRIM_TERM}" -H 'Content-Type: application/json' -d @"${TMPPATH}/${SM_TEMPLATE}"
      if [ $? -ne 0 ]; then
        echo "Failed to upload ${TMPPATH}/${SM_TEMPLATE}!"
        exit 1
      fi
      cat "${TMPPATH}/${SM_TEMPLATE}"
      export NEW_CLUSTER_RETENTION_SCHEMA_VERSION=$(curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/snapshot-${e}-delete-policy"|jq .sm_policy.schema_version?)
      echo -e "\nNew schema_version is: ${NEW_CLUSTER_RETENTION_SCHEMA_VERSION}\n, increase this value by 1 to install new sm policy for snapshot-${e}-delete-policy\n" 
    else
      echo "No changes, sm template is not updated. Increase the version number to upload a new sm template"
    fi
  fi
done