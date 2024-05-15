#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

export JQ_RESTORE_TIMESTAMP=$(date --utc --date="${RESTORE_TIMESTAMP}" +'%Y-%m-%dT%H:%M:%S')
export JQ_DATE_FORMAT='%Y-%m-%dT%H:%M:%S'

function fetchkopiafullbackupsnapshotid {
  local int

  if [ "${RESTORE_SNAPSHOT_ID}" == "false" ] || [ "${RESTORE_POINT_IN_TIME}" == "true" ]; then
    if [ "${RESTORE_TIMESTAMP}" == "false" ]; then
      logerror "${FUNCNAME[0]}" "no RESTORE_TIMESTAMP or RESTORE_SNAPSHOT_ID defined. Check the mariadb.galera.restore.beforeTimestamp and mariadb.galera.restore.kopia.snapshotId config options"
      exit 1
    else
      for (( int=${MAX_RETRIES}; int >=1; int-=1));
        do
        KOPIA_SNAPSHOT_ID=$(kopia snapshot list --all --no-incomplete --json --tags=backup.type:dump | jq --exit-status --raw-output \
          --arg r "${JQ_RESTORE_TIMESTAMP}" \
          --arg f "${JQ_DATE_FORMAT}" \
          '[.[] | . as $parent | (.startTime | split(".")[0] | strptime($f)) | select( . <= ($r | strptime($f))) | $parent] | last | .rootEntry.obj')
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

function fetchkopiabackupstarttime {
  local int
  local KOPIA_SNAPSHOT_ID=${1}
  local KOPIA_START_TIMESTAMP

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    KOPIA_START_TIMESTAMP=$(kopia snapshot list --all --no-incomplete --json | jq --exit-status --raw-output \
      --arg s "${KOPIA_SNAPSHOT_ID}" \
      '.[] | select(.rootEntry.obj == $s) | .startTime | split(".")[0]')
    if [ $? -ne 0 ]; then
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done

  echo ${KOPIA_START_TIMESTAMP}
}

function fetchkopiabackupstartposition {
  local int
  local KOPIA_SNAPSHOT_ID=${1}
  local KOPIA_START_POSITION

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    KOPIA_START_POSITION=$(kopia snapshot list --all --no-incomplete --json | jq --exit-status --raw-output \
      --arg s "${KOPIA_SNAPSHOT_ID}" \
      '.[] | select(.rootEntry.obj == $s) | .tags."tag:mariadb.binlogposition"')
    if [ $? -ne 0 ]; then
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done

  echo ${KOPIA_START_POSITION}
}

function fetchkopiabinlogbackupsnapshotid {
  local int
  local KOPIA_START_TIMESTAMP=${1}
  local KOPIA_BINLOG_SNAPSHOT

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    KOPIA_BINLOG_SNAPSHOT=$(kopia snapshot list --all --no-incomplete --json --tags=backup.type:binlog | jq --exit-status --raw-output \
      --arg r "${JQ_RESTORE_TIMESTAMP}" \
      --arg s "${KOPIA_START_TIMESTAMP}" \
      --arg f "${JQ_DATE_FORMAT}" \
      '[.[] | . as $parent | .startTime | split(".")[0] | strptime($f) | select ( . >= ($s | strptime($f)) and . <= ($r | strptime($f))) | $parent] | last')
    if [ $? -ne 0 ]; then
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done

  echo ${KOPIA_BINLOG_SNAPSHOT}
}

function recoverkopiafullbackup {
  if [ "${RESTORE_TIMESTAMP}" != "false" ]; then
    loginfo "${FUNCNAME[0]}" "fetch kopia snapshotid for the '${RESTORE_TIMESTAMP}' timestamp"
  else
    loginfo "${FUNCNAME[0]}" "fetch kopia snapshotid"
  fi

  local snapshotid=$(fetchkopiafullbackupsnapshotid)

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

function recoverkopiapointintime {
  loginfo "${FUNCNAME[0]}" "fetch kopia snapshotid for the '${RESTORE_TIMESTAMP}' timestamp"
  local snapshotid=$(fetchkopiafullbackupsnapshotid)
  if [ "${snapshotid}" == "null" ]; then
    logerror "${FUNCNAME[0]}" "no (valid) snapshotId found"
    loginfo "${FUNCNAME[0]}" "The following timestamps are available: $(kopia snapshot list --all --no-incomplete --json --tags=backup.type:dump | jq --exit-status --raw-output '.[].startTime | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("%Y-%m-%d %H:%M:%S")')"
    exit 1
  fi

  loginfo "${FUNCNAME[0]}" "fetch kopia backup starttime for the snapshotid '${snapshotid}'"
  local starttime=$(fetchkopiabackupstarttime ${snapshotid})
  if [ "${starttime}" == "null" ]; then
    logerror "${FUNCNAME[0]}" "no backup start time for the snapshot '${snapshotid}' found"
    loginfo "${FUNCNAME[0]}" "The following metadata is available: $(kopia snapshot list --all --no-incomplete --json --tags=backup.type:dump | jq --exit-status --raw-output --arg s "${snapshotid}" '.[] | select(.rootEntry.obj == "$s")')"
    exit 1
  fi

  loginfo "${FUNCNAME[0]}" "fetch kopia backup startposition for the snapshotid '${snapshotid}'"
  local startposition=$(fetchkopiabackupstartposition ${snapshotid})
  if [ "${startposition}" == "null" ]; then
    logerror "${FUNCNAME[0]}" "no backup start position for the snapshot '${snapshotid}' found"
    loginfo "${FUNCNAME[0]}" "The following metadata is available: $(kopia snapshot list --all --no-incomplete --json --tags=backup.type:dump | jq --exit-status --raw-output --arg s "${snapshotid}" '.[] | select(.rootEntry.obj == "$s")')"
    exit 1
  fi

  loginfo "${FUNCNAME[0]}" "fetch kopia binlog snapshot for the requested timeframe"
  local binlogsnapshot=$(fetchkopiabinlogbackupsnapshotid ${starttime})
  if [ "${binlogsnapshot}" == "null" ]; then
    logerror "${FUNCNAME[0]}" "no binlog snapshot infos found between '${starttime}' and '${JQ_RESTORE_TIMESTAMP}'"
    exit 1
  fi

  loginfo "${FUNCNAME[0]}" "kopia database recovery from '${starttime}' to ${DB_HOST} started"
  kopia show ${snapshotid}/dump.sql | mysql --protocol=tcp --host=${DB_HOST} --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --port=${MYSQL_PORT} --wait --connect-timeout=${WAIT_SECONDS} --reconnect --batch
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "kopia database recovery failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "kopia database recovery done"

  cd /opt/${SOFTWARE_NAME}/var/tmp/binlog

  local binlogsnapshotid=$(jq --exit-status --raw-output --argjson j "${binlogsnapshot}" -n '$j.rootEntry.obj')
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "binlog snapshot id cannot be parsed"
    exit 1
  fi

  local binlogstarttime=$(jq --exit-status --raw-output --argjson j "${binlogsnapshot}" -n '$j.startTime | split(".")[0]')
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "binlog snapshot start time cannot be parsed"
    exit 1
  fi

  local binlogfilelist=$(kopia show ${binlogsnapshotid} | jq --exit-status -c '.entries')
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "binlog file list for snapshot '${binlogsnapshotid}' cannot be parsed"
    exit 1
  fi

  local binlogfilecount=$(kopia show ${binlogsnapshotid} | jq --exit-status -c '.entries | length')
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "binlog file count for snapshot '${binlogsnapshotid}' cannot be parsed"
    exit 1
  fi

  local binlogfilenr=1
  loginfo "${FUNCNAME[0]}" "starting kopia binlog recovery from '${binlogstarttime}+UTC' to ${DB_HOST}"
  for binlogfile in $(jq --exit-status --argjson j "${binlogfilelist}" -c -n '$j[]');
    do
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "binlog file list cannot be parsed"
      exit 1
    fi

    local binlogfilename=$(jq --exit-status --raw-output --argjson j "${binlogfile}" -n '$j.name')
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "binlog file name cannot be parsed"
      exit 1
    fi

    local binlogfilesnapshotid=$(jq --exit-status --raw-output --argjson j "${binlogfile}" -n '$j.obj')
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "binlog file snapshot id cannot be parsed"
      exit 1
    fi

    kopia show ${binlogfilesnapshotid} > ${binlogfilename}
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "kopia binlog restore for '${binlogfilename}' inside the snapshot '${binlogfilesnapshotid}' failed"
      exit 1
    fi

    loginfo "${FUNCNAME[0]}" "kopia binlog recovery using '${binlogfilename}'[${binlogfilenr}/${binlogfilecount}] started"
    {{- /* only the first binlog contains the requested position */}}
    if [ ${binlogfilenr} -eq 1 ]; then
      mariadb-binlog --disable-log-bin --start-position=${startposition} --stop-datetime="${JQ_RESTORE_TIMESTAMP}" ${binlogfilename} | mysql --protocol=tcp --host=${DB_HOST} --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --port=${MYSQL_PORT} --wait --connect-timeout=${WAIT_SECONDS} --reconnect --batch
    else
      mariadb-binlog --disable-log-bin --stop-datetime="${JQ_RESTORE_TIMESTAMP}" ${binlogfilename} | mysql --protocol=tcp --host=${DB_HOST} --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --port=${MYSQL_PORT} --wait --connect-timeout=${WAIT_SECONDS} --reconnect --batch
    fi
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "kopia binlog recovery for '${binlogfilename}' inside the snapshot '${binlogfilesnapshotid}' failed"
      exit 1
    fi
    loginfo "${FUNCNAME[0]}" "kopia binlog recovery done"

    rm /opt/${SOFTWARE_NAME}/var/tmp/binlog/${binlogfilename}
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "kopia binlog file '${binlogfilename}' cannot be deleted"
      exit 1
    fi
    let "binlogfilenr+=1"
  done
}

initkopiarepo
{{- if $.Values.mariadb.galera.restore.pointInTimeRecovery }}
recoverkopiapointintime
{{- else  }}
recoverkopiafullbackup
{{- end }}
