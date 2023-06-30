#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function fetchkopiasnapshotid {
  local int
  if [ "${RESTORE_SNAPSHOT_ID}" == "false" ]; then
    if [ "${RESTORE_TIMESTAMP}" == "false" ]; then
      logerror "${FUNCNAME[0]}" "no RESTORE_TIMESTAMP or RESTORE_SNAPSHOT_ID defined. Check the mariadb.galera.restore.beforeTimestamp and mariadb.galera.restore.kopia.snapshotId config options"
      exit 1
    else
      for (( int=${MAX_RETRIES}; int >=1; int-=1));
        do
        KOPIA_SNAPSHOT_ID=$(kopia snapshot list --all --no-incomplete --json --tags=backup.type:dump | jq --exit-status --raw-output '[.[] | select (.startTime | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") <= (env.RESTORE_TIMESTAMP | strptime("%Y-%m-%d %H:%M:%S")))] | last | .rootEntry.obj')
        if [ $? -ne 0 ]; then
          sleep ${WAIT_SECONDS}
        else
          break
        fi
      done
    fi
  else
    for (( int=${MAX_RETRIES}; int >=1; int-=1));
      do
      kopia show ${RESTORE_SNAPSHOT_ID} | jq --exit-status --raw-output '.summary | select(.numFailed == 0) | .numFailed' > /dev/null
      if [ $? -ne 0 ]; then
        sleep ${WAIT_SECONDS}
      else
        KOPIA_SNAPSHOT_ID=${RESTORE_SNAPSHOT_ID}
        break
      fi
    done
  fi

  echo ${KOPIA_SNAPSHOT_ID}
}

function recoverkopiadbbackup {
  if [ "${RESTORE_TIMESTAMP}" != "false" ]; then
    loginfo "${FUNCNAME[0]}" "fetch kopia snapshotid for the '${RESTORE_TIMESTAMP}' timestamp"
  else
    loginfo "${FUNCNAME[0]}" "fetch kopia snapshotid"
  fi

  local snapshotid=$(fetchkopiasnapshotid)

  if [ "${snapshotid}" == "null" ]; then
    logerror "${FUNCNAME[0]}" "no (valid) snapshotId found"
    loginfo "${FUNCNAME[0]}" "The following timestamps are available: $(kopia snapshot list --all --no-incomplete --json --tags=backup.type:dump | jq --raw-output '.[].startTime | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("%Y-%m-%d %H:%M:%S")')"
    exit 1
  fi

  loginfo "${FUNCNAME[0]}" "kopia database recovery using snapshot ${snapshotid} to ${DB_HOST} started"
  kopia show ${snapshotid}/dump.sql | mysql --protocol=tcp --host=${DB_HOST} --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --port=${MYSQL_PORT} --wait --connect-timeout=${WAIT_SECONDS} --reconnect --batch
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "kopia database recovery failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "kopia database recovery done"
}

initkopiarepo
recoverkopiadbbackup