MAX_RETRIES={{ $.Values.scripts.maxRetries | default 10 }}
WAIT_SECONDS={{ $.Values.scripts.waitTimeBetweenRetriesInSeconds | default 6 }}
declare -a NODENAME=()

function fetchseqnofromremotenode {
  local int
  local SEQNOARRAY
  local DB_HOST=${1}

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    IFS=$'\t' SEQNOARRAY=($(mysql --protocol=tcp --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --host=${DB_HOST}.database.svc.cluster.local --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.application }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_last_committed';" --batch --skip-column-names | grep 'wsrep_last_committed'))
    if [ $? -ne 0 ]; then
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    exit 1
  fi
  IFS="${oldIFS}"
  echo ${DB_HOST}:${SEQNOARRAY[1]}
}

function selectbackupnode {
  local int

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "Find Galera node with highest sequence number (${int} retries left)"
    IFS=": " NODENAME=($(cat /tmp/nodelist.seqno | sort --key=2 --reverse --numeric-sort --field-separator=: | head -1))
    IFS="${oldIFS}"
    if [[ "${NODENAME[0]}" =~ ^{{ (include "nodeNamePrefix" (dict "global" $ "component" "application")) }}-.* ]]; then
      loginfo "${FUNCNAME[0]}" "Galera nodename '${NODENAME[0]}' with the sequence number '${NODENAME[1]}' selected"
      break
    else
      logerror "${FUNCNAME[0]}" "nodename '${NODENAME[0]}' not valid"
      exit 1
    fi
  done

  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "Sequence number search finally failed)"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "Sequence number search done"
}

function setclusterdesyncmode {
  local int
  local DB_HOST=${1}
  local DISABLESYNC=${2}

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    loginfo "${FUNCNAME[0]}" "set cluster desync ${DISABLESYNC} for node ${DB_HOST} (${int} retries left)"
    mysql --protocol=tcp --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --host=${DB_HOST}.database.svc.cluster.local --port=${MYSQL_PORT} --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.application }} --execute="SET GLOBAL wsrep_desync = ${DISABLESYNC};" --batch --skip-column-names
    if [ $? -ne 0 ]; then
      sleep ${WAIT_SECONDS}
    else
      break
    fi
  done
  if [ ${int} -eq 0 ]; then
    logerror "${FUNCNAME[0]}" "set cluster desync ${DISABLESYNC} for node ${DB_HOST} finally failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "set cluster desync done"
}

function queryoldestbinlogname {
  local DB_HOST=${1}
  local BINLOGNAME

  IFS=$'\t' BINLOGNAME=($(mysql --protocol=tcp --host=${DB_HOST}.database.svc.cluster.local --port=${MYSQL_PORT} --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --execute="SHOW GLOBAL STATUS LIKE 'Binlog_snapshot_file';" --batch --skip-column-names))
  IFS="${oldIFS}"
  if [ $? -ne 0 ]; then
    exit 1
  fi
  echo ${BINLOGNAME[1]}
}

function unlockresticrepo {
  loginfo "${FUNCNAME[0]}" "unlock restic repository if required"
  restic unlock --remove-all --json
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "restic repository unlock failed"
    exit 1
  else
    loginfo "${FUNCNAME[0]}" "restic repository unlock done"
  fi
}

function pruneresticbackups {
  loginfo "${FUNCNAME[0]}" "remove old restic backups if required"
  restic forget --prune \
                --keep-last {{ $.Values.mariadb.galera.backup.restic.keep.last | default 2 | int }} \
                --keep-hourly {{ $.Values.mariadb.galera.backup.restic.keep.hourly | default 24 | int }} \
                --keep-daily {{ $.Values.mariadb.galera.backup.restic.keep.daily | default 1 | int }} \
                --keep-weekly {{ $.Values.mariadb.galera.backup.restic.keep.weekly | default 0 | int }} \
                --keep-monthly {{ $.Values.mariadb.galera.backup.restic.keep.monthly | default 0 | int }} \
                --keep-yearly {{ $.Values.mariadb.galera.backup.restic.keep.yearly | default 0 | int }} \
                --compact --quiet
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "restic backup pruning failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "restic backup pruning done"
}

function checkresticrepo {
  loginfo "${FUNCNAME[0]}" "check restic repository structure"
  restic check --json --quiet
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "restic check failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "restic check done"
}


function expirekopiabackups {
  loginfo "${FUNCNAME[0]}" "remove old kopia snapshots if required"
  kopia snapshot expire /mariadb.${MARIADB_BACKUP_TYPE} \
                --delete \
                --progress-update-interval={{ $.Values.mariadb.galera.backup.kopia.progressUpdateInterval | default "300ms" | quote }}
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "kopia snapshot removal failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "kopia snapshot removal done"
}

function listresticbackups {
  loginfo "${FUNCNAME[0]}" "list available restic backups"
  restic snapshots --json
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "restic backup listing failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "restic backup listing done"
}

function listkopiabackups {
  loginfo "${FUNCNAME[0]}" "list available kopia backups"
  kopia snapshot list /mariadb \
                --json \
                --all \
                --progress-update-interval={{ $.Values.mariadb.galera.backup.kopia.progressUpdateInterval | default "300ms" | quote }}
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "kopia backup listing failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "kopia backup listing done"
}

function initkopiarepo {
  loginfo "${FUNCNAME[0]}" "init kopia repository if required"
  kopia repository connect ${KOPIA_REPOSITORY_TYPE} \
            --endpoint=${KOPIA_S3_ENDPOINT} --region=${KOPIA_S3_REGION} \
            --bucket=${KOPIA_S3_BUCKET} \
            --access-key=${KOPIA_S3_USERNAME} --secret-access-key=${KOPIA_S3_PASSWORD} \
            --override-hostname=backup-kopia \
            --progress-update-interval={{ $.Values.mariadb.galera.backup.kopia.progressUpdateInterval | default "300ms" | quote }}
  if [ $? -ne 0 ]; then
    loginfo "${FUNCNAME[0]}" "No kopia repository found"
    kopia repository create ${KOPIA_REPOSITORY_TYPE} \
            --endpoint=${KOPIA_S3_ENDPOINT} --region=${KOPIA_S3_REGION} \
            --bucket=${KOPIA_S3_BUCKET} \
            --access-key=${KOPIA_S3_USERNAME} --secret-access-key=${KOPIA_S3_PASSWORD} \
            --override-hostname=backup-kopia \
            --ecc=REED-SOLOMON-CRC32 --ecc-overhead-percent=2 \
            --object-splitter=DYNAMIC-8M-BUZHASH \
            --progress-update-interval={{ $.Values.mariadb.galera.backup.kopia.progressUpdateInterval | default "300ms" | quote }}
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "kopia repository initialization failed"
      exit 1
    else
      loginfo "${FUNCNAME[0]}" "kopia repository initialization done"
    fi
  else
    loginfo "${FUNCNAME[0]}" "kopia repository already exist"
  fi
}
