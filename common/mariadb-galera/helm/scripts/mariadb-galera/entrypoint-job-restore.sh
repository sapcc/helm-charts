#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function fetchresticsnapshotid {
  local int
  if [ "${RESTORE_SNAPSHOT_ID}" == "false" ]; then
    if [ "${RESTORE_TIMESTAMP}" == "false" ]; then
      logerror "${FUNCNAME[0]}" "no RESTORE_TIMESTAMP or RESTORE_SNAPSHOT_ID defined. Check the mariadb.galera.restore.beforeTimestamp and mariadb.galera.restore.restic.snapshotId configb options"
      exit 1
    else
      for (( int=${MAX_RETRIES}; int >=1; int-=1));
        do
        RESTIC_SNAPSHOT_ID=$(restic snapshots --tag dump --json | jq -r '[.[] | select (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") <= (env.RESTORE_TIMESTAMP | strptime("%Y-%m-%d %H:%M:%S")))] | last | .short_id')
        if [ $? -ne 0 ]; then
          sleep ${WAIT_SECONDS}
        else
          break
        fi
      done
    fi
  else
    # Does not work because of https://github.com/restic/restic/issues/4087
    # for (( int=${MAX_RETRIES}; int >=1; int-=1));
    #   do
    #   restic stats --json ${RESTORE_SNAPSHOT_ID} >/dev/null 2>&1
    #   if [ $? -ne 0 ]; then
    #     sleep ${WAIT_SECONDS}
    #   else
    #     break
    #   fi
    # done
    RESTIC_SNAPSHOT_ID=${RESTORE_SNAPSHOT_ID}
  fi

  if [ ${int} -eq 0 ]; then
    exit 1
  fi
  echo ${RESTIC_SNAPSHOT_ID}
}

function recoverresticdbbackup {
  loginfo "${FUNCNAME[0]}" "fetch restic snapshotid for ${RESTORE_TIMESTAMP} timestamp"
  local snapshotid=$(fetchresticsnapshotid)
  loginfo "${FUNCNAME[0]}" "restic database recovery using snapshot ${snapshotid} to ${DB_HOST} started"
  restic dump --tag dump ${snapshotid} mariadb.dump | mysql --protocol=tcp --host=${DB_HOST} --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --port=${MYSQL_PORT} --wait --connect-timeout=${WAIT_SECONDS} --reconnect --batch
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "restic database recovery failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "restic database recovery done"
}

recoverresticdbbackup