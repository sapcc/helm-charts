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
### REMOVE remote_.ds-${e}-datastream* indexes from ${e}-ds alias and ADD to remote-${e} alias
####
for e in ${DATA_STREAMS}; do
  echo "Processing remotes for data stream: ${e}"

  # Step 1: Get all indices with alias ${e}-ds
  ALIAS_RESPONSE=$(curl -s --netrc-file "${NETRC_FILE}" -XGET "${CLUSTER_HOST}/_alias/${e}-ds")
  if [ $? -ne 0 ]; then
    echo "Failed to get alias ${e}-ds, skipping..."
    continue
  fi

  # Step 2: Extract index names starting with "remote_"
  REMOTE_INDICES=$(echo "${ALIAS_RESPONSE}" | jq -r 'keys[] | select(startswith("remote_"))' | tr '\n' ' ')

  if [ -z "${REMOTE_INDICES}" ]; then
    echo "No remote indices found in ${e}-ds alias, skipping..."
    continue
  fi

  # Build JSON arrays for the actions payload
  INDICES_JSON=$(echo "${REMOTE_INDICES}" | tr ' ' '\n' | grep -v '^$' | jq -R . | jq -s .)

  ACTIONS_PAYLOAD=$(jq -n \
    --argjson indices "${INDICES_JSON}" \
    --arg old_alias "${e}-ds" \
    --arg new_alias "remote-${e}" \
    '{
      "actions": [
        {
          "remove": {
            "indices": $indices,
            "alias": $old_alias
          }
        },
        {
          "add": {
            "indices": $indices,
            "alias": $new_alias
          }
        }
      ]
    }')

  # Step 3: Apply alias changes
  echo "Alias change actions: ${ACTIONS_PAYLOAD}"
  RESPONSE=$(curl -s --netrc-file "${NETRC_FILE}" -X POST "${CLUSTER_HOST}/_aliases" \
    -H 'Content-Type: application/json' \
    -d "${ACTIONS_PAYLOAD}")

  if echo "${RESPONSE}" | jq -e '.acknowledged == true' > /dev/null 2>&1; then
    echo "Successfully updated aliases for ${e}: removed from ${e}-ds, added to remote-${e}"
  else
    echo "Failed to update aliases for ${e}: ${RESPONSE}"
  fi

done

####
### Get all remote_.ds-${e}-datastream* indexes and if missing - add to remote-${e} alias 
####
for e in ${DATA_STREAMS}; do
  # Step 4: Get ALL remote* indices via _cat (includes those not yet in any alias)
  ALL_REMOTE_RESPONSE=$(curl -s --netrc-file "${NETRC_FILE}" \
    "${CLUSTER_HOST}/_cat/indices/remote_.ds-${e}*?expand_wildcards=all&format=json")
  if [ $? -ne 0 ]; then
    echo "Failed to get all remote indices for ${e}, skipping missing-alias check..."
    continue
  fi

  ALL_REMOTE_INDICES=$(echo "${ALL_REMOTE_RESPONSE}" | jq -r '.[].index')

  if [ -z "${ALL_REMOTE_INDICES}" ]; then
    echo "No remote_.ds-${e}* indices found via _cat, skipping..."
    continue
  fi

  # Get indices already in remote-${e} alias
  EXISTING_REMOTE_ALIAS_RESPONSE=$(curl -s --netrc-file "${NETRC_FILE}" \
    "${CLUSTER_HOST}/_alias/remote-${e}")
  EXISTING_IN_ALIAS=$(echo "${EXISTING_REMOTE_ALIAS_RESPONSE}" | jq -r 'keys[]' 2>/dev/null || echo "")

  # Find indices not yet in remote-${e}
  MISSING_INDICES=""
  while IFS= read -r idx; do
    if ! echo "${EXISTING_IN_ALIAS}" | grep -qx "${idx}"; then
      MISSING_INDICES="${MISSING_INDICES} ${idx}"
    fi
  done <<< "${ALL_REMOTE_INDICES}"

  MISSING_INDICES=$(echo "${MISSING_INDICES}" | tr ' ' '\n' | grep -v '^$')

  if [ -z "${MISSING_INDICES}" ]; then
    echo "All remote_.ds-${e}* indices already in remote-${e} alias"
    continue
  fi

  MISSING_INDICES_JSON=$(echo "${MISSING_INDICES}" | jq -R . | jq -s .)

  ADD_PAYLOAD=$(jq -n \
    --argjson indices "${MISSING_INDICES_JSON}" \
    --arg new_alias "remote-${e}" \
    '{
      "actions": [
        {
          "add": {
            "indices": $indices,
            "alias": $new_alias
          }
        }
      ]
    }')

  echo "Adding missing indices to remote-${e} alias: ${ADD_PAYLOAD}"
  ADD_RESPONSE=$(curl -s --netrc-file "${NETRC_FILE}" -X POST "${CLUSTER_HOST}/_aliases" \
    -H 'Content-Type: application/json' \
    -d "${ADD_PAYLOAD}")

  if echo "${ADD_RESPONSE}" | jq -e '.acknowledged == true' > /dev/null 2>&1; then
    echo "Successfully added missing indices to remote-${e}"
  else
    echo "Failed to add missing indices to remote-${e}: ${ADD_RESPONSE}"
  fi
done