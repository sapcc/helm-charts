#!/bin/bash
# Creates the hermes* index pattern in Dashboards so Discover offers the hermes data stream.
# Keeps an existing pattern with the same title and only fills in a missing field list.
set -uo pipefail

DASHBOARDS_URL="http://opensearch-hermes-dashboards:5601"
PATTERN_ID="hermes"
PATTERN_TITLE="hermes*"
TIME_FIELD="eventTime"

NETRC_FILE=$(mktemp)
trap 'rm -f "${NETRC_FILE}"' EXIT

dashboards() {
  curl -s --netrc-file "${NETRC_FILE}" -H "osd-xsrf: true" -H "securitytenant: global" -H "Content-Type: application/json" "$@"
}

status_code() {
  dashboards -o /dev/null -w "%{http_code}" "${DASHBOARDS_URL}/api/status"
}

echo "Waiting for ${DASHBOARDS_URL}"
for attempt in $(seq 1 60); do
  echo "machine opensearch-hermes-dashboards login ${ADMIN_USER} password ${ADMIN_PASSWORD}" > "${NETRC_FILE}"
  [ "$(status_code)" = "200" ] && break
  echo "machine opensearch-hermes-dashboards login ${ADMIN2_USER} password ${ADMIN2_PASSWORD}" > "${NETRC_FILE}"
  [ "$(status_code)" = "200" ] && break
  if [ "${attempt}" -eq 60 ]; then
    echo "Dashboards not ready or both admin users rejected, giving up"
    exit 1
  fi
  sleep 5
done

# Discover needs the field list stored on the pattern, otherwise the time field cannot be resolved.
# Bodies go through stdin because large field lists exceed the per-argument size limit.
pattern_body() {
  dashboards --fail "${DASHBOARDS_URL}/api/index_patterns/_fields_for_wildcard?pattern=${PATTERN_TITLE/\*/%2A}&meta_fields=_source&meta_fields=_id&meta_fields=_type&meta_fields=_index&meta_fields=_score" \
    | jq -ce --arg t "${PATTERN_TITLE}" --arg tf "$1" '{attributes: {title: $t, timeFieldName: $tf, fields: (.fields // error("no fields") | tojson)}}'
}

save_pattern() {
  dashboards -o /dev/null -w "%{http_code}" -X"$1" "${DASHBOARDS_URL}/api/saved_objects/index-pattern/$2" --data-binary @-
}

if ! PATTERNS=$(dashboards --fail "${DASHBOARDS_URL}/api/saved_objects/_find?type=index-pattern&per_page=1000" \
  | jq -ce --arg t "${PATTERN_TITLE}" '[.saved_objects[] | select(.attributes.title == $t) | {id, timeFieldName: .attributes.timeFieldName, hasFields: ((.attributes.fields // "[]") != "[]")}]'); then
  echo "Could not list index patterns"
  exit 1
fi

if [ "$(echo "${PATTERNS}" | jq length)" -gt 0 ]; then
  # Keep existing patterns, only fill in a missing field list
  for ID in $(echo "${PATTERNS}" | jq -r '.[] | select(.hasFields | not) | .id'); do
    echo "Index pattern ${PATTERN_TITLE} (${ID}) has no field list, refreshing it"
    TF=$(echo "${PATTERNS}" | jq -r --arg id "${ID}" '.[] | select(.id == $id) | .timeFieldName // empty')
    if ! BODY=$(pattern_body "${TF:-${TIME_FIELD}}"); then
      echo "Could not read fields for ${PATTERN_TITLE}"
      exit 1
    fi
    CODE=$(echo "${BODY}" | save_pattern PUT "${ID}")
    if [ "${CODE}" != "200" ]; then
      echo "Refreshing fields of ${ID} failed with HTTP ${CODE}"
      exit 1
    fi
  done
  echo "Index pattern ${PATTERN_TITLE} is present"
else
  echo "Creating index pattern ${PATTERN_TITLE}"
  if ! BODY=$(pattern_body "${TIME_FIELD}"); then
    echo "Could not read fields for ${PATTERN_TITLE}"
    exit 1
  fi
  CODE=$(echo "${BODY}" | save_pattern POST "${PATTERN_ID}")
  # 409 means the id is already taken by a pattern with another title, which is left alone
  if [ "${CODE}" != "200" ] && [ "${CODE}" != "409" ]; then
    echo "Creating index pattern failed with HTTP ${CODE}"
    exit 1
  fi
fi

if ! SETTINGS=$(dashboards --fail "${DASHBOARDS_URL}/api/opensearch-dashboards/settings"); then
  echo "Could not read advanced settings"
  exit 1
fi
DEFAULT=$(echo "${SETTINGS}" | jq -r '.settings.defaultIndex.userValue // empty')
if [ -z "${DEFAULT}" ]; then
  echo "No default index pattern set, using ${PATTERN_ID}"
  if ! dashboards --fail -o /dev/null -XPOST "${DASHBOARDS_URL}/api/opensearch-dashboards/settings" -d "{\"changes\": {\"defaultIndex\": \"${PATTERN_ID}\"}}"; then
    echo "Setting the default index pattern failed"
    exit 1
  fi
fi
echo "Done"
