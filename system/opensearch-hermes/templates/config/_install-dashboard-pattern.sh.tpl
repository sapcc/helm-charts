#!/bin/bash
# Creates the hermes* index pattern in Dashboards so Discover offers the hermes data stream.
# Leaves an existing pattern with the same title alone, so manually created ones are kept.
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

EXISTING=$(dashboards "${DASHBOARDS_URL}/api/saved_objects/_find?type=index-pattern&fields=title&per_page=1000" \
  | jq -r --arg t "${PATTERN_TITLE}" '[.saved_objects[] | select(.attributes.title == $t)] | length')
if [ -z "${EXISTING}" ]; then
  echo "Could not list index patterns"
  exit 1
fi

if [ "${EXISTING}" -gt 0 ]; then
  echo "Index pattern ${PATTERN_TITLE} already exists"
else
  echo "Creating index pattern ${PATTERN_TITLE}"
  CODE=$(dashboards -o /dev/null -w "%{http_code}" -XPOST "${DASHBOARDS_URL}/api/saved_objects/index-pattern/${PATTERN_ID}" \
    -d "{\"attributes\": {\"title\": \"${PATTERN_TITLE}\", \"timeFieldName\": \"${TIME_FIELD}\"}}")
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
