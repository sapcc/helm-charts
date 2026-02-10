#!/bin/bash
#
# Copyright (c) 2024 SAP SE
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#

set -euo pipefail

unset http_proxy https_proxy all_proxy no_proxy

log() {
  echo "$(date -Is) [BARBICAN-NANNY] $*"
}

is_true() {
  case "${1:-}" in
    True|true|TRUE|1|yes|YES|y|Y) return 0 ;;
    *) return 1 ;;
  esac
}

# ---- Existing env (kept compatible) ----
: "${BARBICAN_DB_SECRET_MOVE_ENABLED:=false}"
: "${BARBICAN_DB_OLD_PROJECT_ID:=}"
: "${BARBICAN_DB_NEW_PROJECT_ID:=}"
: "${BARBICAN_NANNY_INTERVAL:=30}"   # minutes

# ---- New (optional) DB clean env ----
: "${BARBICAN_DB_CLEAN_ENABLED:=false}"
: "${BARBICAN_DB_CLEAN_INTERVAL_MINUTES:=1440}"  # default: daily
: "${BARBICAN_DB_CLEAN_MIN_DAYS:=180}"           # default: 180
: "${BARBICAN_DB_CLEAN_CLEAN_UNASSOCIATED_PROJECTS:=false}"
: "${BARBICAN_DB_CLEAN_SOFT_DELETE_EXPIRED_SECRETS:=false}"
: "${BARBICAN_DB_CLEAN_VERBOSE:=false}"
: "${BARBICAN_DB_CLEAN_ALLOW_MIN_DAYS_ZERO:=false}"  # safety guard

run_move_secrets() {
  if ! is_true "${BARBICAN_DB_SECRET_MOVE_ENABLED}"; then
    return 0
  fi

  if [[ -z "${BARBICAN_DB_OLD_PROJECT_ID}" || -z "${BARBICAN_DB_NEW_PROJECT_ID}" ]]; then
    log "WARN: move_secrets enabled but BARBICAN_DB_OLD_PROJECT_ID/BARBICAN_DB_NEW_PROJECT_ID not set; skipping"
    return 0
  fi

  log "INFO: running move_secrets old_project_id=${BARBICAN_DB_OLD_PROJECT_ID} new_project_id=${BARBICAN_DB_NEW_PROJECT_ID}"
  /var/lib/openstack/bin/barbican-manage sap move_secrets \
    --old-project-id "${BARBICAN_DB_OLD_PROJECT_ID}" \
    --new-project-id "${BARBICAN_DB_NEW_PROJECT_ID}"
}

run_db_clean() {
  if ! is_true "${BARBICAN_DB_CLEAN_ENABLED}"; then
    return 0
  fi

  # Guardrail: prevent accidental "delete everything"
  if [[ "${BARBICAN_DB_CLEAN_MIN_DAYS}" == "0" ]] && ! is_true "${BARBICAN_DB_CLEAN_ALLOW_MIN_DAYS_ZERO}"; then
    log "ERROR: BARBICAN_DB_CLEAN_MIN_DAYS=0 is blocked unless BARBICAN_DB_CLEAN_ALLOW_MIN_DAYS_ZERO=true"
    return 1
  fi

  local args=(db clean --min-days "${BARBICAN_DB_CLEAN_MIN_DAYS}")

  if is_true "${BARBICAN_DB_CLEAN_CLEAN_UNASSOCIATED_PROJECTS}"; then
    args+=(--clean-unassociated-projects)
  fi

  if is_true "${BARBICAN_DB_CLEAN_SOFT_DELETE_EXPIRED_SECRETS}"; then
    args+=(--soft-delete-expired-secrets)
  fi

  if is_true "${BARBICAN_DB_CLEAN_VERBOSE}"; then
    args+=(--verbose)
  fi

  log "INFO: running barbican-manage ${args[*]}"
  /var/lib/openstack/bin/barbican-manage "${args[@]}"
}

log "INFO: starting a loop to periodically run Barbican nanny jobs"
log "INFO: move_secrets enabled=${BARBICAN_DB_SECRET_MOVE_ENABLED}, interval=${BARBICAN_NANNY_INTERVAL}m"
log "INFO: db_clean enabled=${BARBICAN_DB_CLEAN_ENABLED}, interval=${BARBICAN_DB_CLEAN_INTERVAL_MINUTES}m, min_days=${BARBICAN_DB_CLEAN_MIN_DAYS}"

last_clean_epoch=0

while true; do
  # 1) secret movement (every loop)
  run_move_secrets

  # 2) db clean (only when due)
  now_epoch="$(date +%s)"
  clean_every="$(( 60 * BARBICAN_DB_CLEAN_INTERVAL_MINUTES ))"

  if (( now_epoch - last_clean_epoch >= clean_every )); then
    if run_db_clean; then
      last_clean_epoch="${now_epoch}"
    else
      log "WARN: db clean failed; will retry on next due interval"
    fi
  fi

  log "INFO: waiting ${BARBICAN_NANNY_INTERVAL} minutes before starting the next loop run"
  sleep "$(( 60 * BARBICAN_NANNY_INTERVAL ))"
done
