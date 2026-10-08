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
  echo "machine ${CLUSTER_HOST_BASE} login ${ADMIN2_USER} password ${ADMIN2_PASSWORD}" > "${NETRC_FILE}"
  curl -s --netrc-file "${NETRC_FILE}" "${CLUSTER_HOST}/"
  if [ $? -ne 0 ]; then
    echo "Second user failed, giving up..."
    exit 1
  fi
fi

export FILEPATH=/scripts
export TMPPATH=/tmp

####
### Maillog ISM policy creation
####
for e in ${INDEX_NAMES}; do
  export POLICY_NAME=index-${e}-ism
  export ISM_TEMPLATE=${POLICY_NAME}.json

  if [ ! -f "${FILEPATH}/${ISM_TEMPLATE}" ]; then
    echo "${FILEPATH}/${ISM_TEMPLATE} is missing."
    exit 1
  fi

  cp "${FILEPATH}/${ISM_TEMPLATE}" "${TMPPATH}/${ISM_TEMPLATE}"
  echo -e "\nApplying ${TMPPATH}/${ISM_TEMPLATE} to ${CLUSTER_HOST}"

  # Replace _SNAPSHOT_NAME_ placeholder with ctx.index for ism plugin
  sed -i "s/_SNAPSHOT_NAME_/{ctx.index}/g" "${TMPPATH}/${ISM_TEMPLATE}"
  if grep -q "_SNAPSHOT_NAME_" "${TMPPATH}/${ISM_TEMPLATE}"; then
    echo "${TMPPATH}/${ISM_TEMPLATE} replacement was not successful."
    exit 1
  fi

  export POLICY_RETURN_CODE=$(curl -s -o /dev/null -w "%{http_code}\n" --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/${POLICY_NAME}")
  echo -e "\nReturn code is $POLICY_RETURN_CODE\n"

  if [ "${POLICY_RETURN_CODE}" -eq 404 ]; then
    echo -e "Initial upload of ${POLICY_NAME} policy"
    echo -e "Upload ism policy, there is no policy \"${POLICY_NAME}\" installed"
    curl --netrc-file "${NETRC_FILE}" -XPUT "${CLUSTER_HOST}/_plugins/_ism/policies/${POLICY_NAME}" -H 'Content-Type: application/json' -d @"${TMPPATH}/${ISM_TEMPLATE}"
    if [ $? -ne 0 ]; then
      echo "Failed to upload ${TMPPATH}/${ISM_TEMPLATE}!"
      exit 1
    fi
  else
    export CLUSTER_RETENTION_RESPONSE=$(curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/${POLICY_NAME}")
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
      curl --netrc-file "${NETRC_FILE}" -XPUT "${CLUSTER_HOST}/_plugins/_ism/policies/${POLICY_NAME}?if_seq_no=${CLUSTER_RETENTION_SEQ_NUMBER}&if_primary_term=${CLUSTER_RETENTION_RUN_PRIM_TERM}" -H 'Content-Type: application/json' -d @"${TMPPATH}/${ISM_TEMPLATE}"
      if [ $? -ne 0 ]; then
        echo "Failed to upload ${TMPPATH}/${ISM_TEMPLATE}!"
        exit 1
      fi
      cat "${TMPPATH}/${ISM_TEMPLATE}"
      export NEW_CLUSTER_RETENTION_SCHEMA_VERSION=$(curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_ism/policies/${POLICY_NAME}" | jq .policy.schema_version?)
      echo -e "\nNew schema_version is: ${NEW_CLUSTER_RETENTION_SCHEMA_VERSION}\n, increase this value by 1 to install new ism policy for ${POLICY_NAME}\n"
    else
      echo "No changes, ism template is not updated. Increase the version number to upload a new ism template"
    fi
  fi
done

####
### Maillog ISM policy verification and attachment
####
for e in ${INDEX_NAMES}; do
  export POLICY_NAME=index-${e}-ism
  # extract country suffix: maillogkr -> kr, mailloges -> es
  export COUNTRY=${e#maillog}
  export INDEX_PATTERN="maillog-*-retention-${COUNTRY}"

  export ISM_EXPLAIN_RESPONSE=${TMPPATH}/ism-explain-${POLICY_NAME}.json
  export ISM_EXPLAIN_HTTP_CODE=$(curl -s -o ${ISM_EXPLAIN_RESPONSE} -w "%{http_code}" --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_ism/explain/${INDEX_PATTERN}")
  echo -e "\nISM explain return code for ${INDEX_PATTERN}: ${ISM_EXPLAIN_HTTP_CODE}\n"

  if [ "${ISM_EXPLAIN_HTTP_CODE}" -ne 200 ]; then
    echo "No indices found for pattern ${INDEX_PATTERN} (HTTP ${ISM_EXPLAIN_HTTP_CODE}), skipping policy attachment."
    continue
  fi

  export TOTAL_MANAGED_INDICES=$(jq '.total_managed_indices' ${ISM_EXPLAIN_RESPONSE})

  export INDICES_WITHOUT_POLICY=$(jq -r \
    'to_entries[] | select(.key != "total_managed_indices") |
     select(.value.policy_id == null or .value.policy_id == "") |
     .key' ${ISM_EXPLAIN_RESPONSE})

  if [ -n "${INDICES_WITHOUT_POLICY}" ]; then
    echo "Found indices without policy, assigning ${POLICY_NAME}:"
    echo "${INDICES_WITHOUT_POLICY}"
    for index in ${INDICES_WITHOUT_POLICY}; do
      echo "Assigning policy to index: ${index}"
      curl --header 'content-type: application/JSON' --netrc-file "${NETRC_FILE}" \
        -XPOST "${CLUSTER_HOST}/_plugins/_ism/add/${index}" \
        -d "{ \"policy_id\": \"${POLICY_NAME}\" }"
    done
  else
    echo "All indices already have a policy assigned for ${POLICY_NAME}"
  fi
done

####
### Maillog snapshot delete policies creation
####
for e in ${INDEX_NAMES}; do
  export SM_POLICY_NAME=snapshot-${e}-delete-policy
  export SM_TEMPLATE=${SM_POLICY_NAME}.json

  if [ ! -f "${FILEPATH}/${SM_TEMPLATE}" ]; then
    echo "${FILEPATH}/${SM_TEMPLATE} not defined. Skipping."
    continue
  fi

  echo -e "\nApplying ${TMPPATH}/${SM_TEMPLATE} to the cluster"
  cp "${FILEPATH}/${SM_TEMPLATE}" "${TMPPATH}/${SM_TEMPLATE}"

  export POLICY_RETURN_CODE=$(curl -s -o /dev/null -w "%{http_code}\n" --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_sm/policies/${SM_POLICY_NAME}")
  echo -e "\nReturn code is $POLICY_RETURN_CODE\n"

  if [ "${POLICY_RETURN_CODE}" -eq 404 ]; then
    echo -e "Initial upload of delete-only sm policy"
    echo -e "Upload sm policy, there is no policy \"${SM_POLICY_NAME}\" installed"
    curl --netrc-file "${NETRC_FILE}" -XPOST "${CLUSTER_HOST}/_plugins/_sm/policies/${SM_POLICY_NAME}" -H 'Content-Type: application/json' -d @"${TMPPATH}/${SM_TEMPLATE}"
    if [ $? -ne 0 ]; then
      echo "Failed to upload ${TMPPATH}/${SM_TEMPLATE}!"
      exit 1
    fi
  else
    export CLUSTER_RETENTION_RESPONSE=$(curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_sm/policies/${SM_POLICY_NAME}")
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
      curl --netrc-file "${NETRC_FILE}" -XPUT "${CLUSTER_HOST}/_plugins/_sm/policies/${SM_POLICY_NAME}?if_seq_no=${CLUSTER_RETENTION_SEQ_NUMBER}&if_primary_term=${CLUSTER_RETENTION_RUN_PRIM_TERM}" -H 'Content-Type: application/json' -d @"${TMPPATH}/${SM_TEMPLATE}"
      if [ $? -ne 0 ]; then
        echo "Failed to upload ${TMPPATH}/${SM_TEMPLATE}!"
        exit 1
      fi
      cat "${TMPPATH}/${SM_TEMPLATE}"
      export NEW_CLUSTER_RETENTION_SCHEMA_VERSION=$(curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_plugins/_sm/policies/${SM_POLICY_NAME}" | jq .sm_policy.schema_version?)
      echo -e "\nNew schema_version is: ${NEW_CLUSTER_RETENTION_SCHEMA_VERSION}, increase this value by 1 to install new sm policy for ${SM_POLICY_NAME}\n"
    else
      echo "No changes, sm template is not updated. Increase the version number to upload a new sm template"
    fi
  fi
done
