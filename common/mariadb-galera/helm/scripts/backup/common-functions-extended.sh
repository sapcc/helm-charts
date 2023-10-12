MAX_RETRIES={{ $.Values.scripts.maxRetries | default 10 }}
WAIT_SECONDS={{ $.Values.scripts.waitTimeBetweenRetriesInSeconds | default 6 }}
declare -a NODENAME=()

function fetchseqnofromremotenode {
  local int
  local SEQNOARRAY
  local DB_HOST=${1}

  for (( int=${MAX_RETRIES}; int >=1; int-=1));
    do
    IFS=$'\t' SEQNOARRAY=($(mysql --protocol=tcp --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --host=${DB_HOST}.{{ $.Release.Namespace }} --port=${MYSQL_PORT} --database=mysql --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.database }} --execute="SHOW GLOBAL STATUS LIKE 'wsrep_last_committed';" --batch --skip-column-names | grep 'wsrep_last_committed'))
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
    if [[ "${NODENAME[0]}" =~ ^{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}-.* ]]; then
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
    mysql --protocol=tcp --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --host=${DB_HOST}.{{ $.Release.Namespace }} --port=${MYSQL_PORT} --connect-timeout={{ $.Values.readinessProbe.timeoutSeconds.database }} --execute="SET GLOBAL wsrep_desync = ${DISABLESYNC};" --batch --skip-column-names
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

  IFS=$'\t' BINLOGNAME=($(mysql --protocol=tcp --host=${DB_HOST}.{{ $.Release.Namespace }} --port=${MYSQL_PORT} --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --execute="SHOW BINARY LOGS;" --batch --skip-column-names | sort --key=1 | head -n 1))
  IFS="${oldIFS}"
  if [ $? -ne 0 ]; then
    exit 1
  fi
  echo ${BINLOGNAME[0]}
}

{{- /* https://mariadb.com/kb/en/purge-binary-logs/ */}}
function purgebinlogfiles {
  local DB_HOST=${1}
  local BINLOGNAME
  local BINLOGNAMEARRAY

  loginfo "${FUNCNAME[0]}" "purge rolled over binlog files on ${DB_HOST}"
  IFS=$'\t' BINLOGNAMEARRAY=($(mysql --protocol=tcp --host=${DB_HOST}.{{ $.Release.Namespace }} --port=${MYSQL_PORT} --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --execute="SHOW BINARY LOGS;" --batch --skip-column-names | sort --key=1 --reverse | awk '{print $1}'))
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "binlog file listing failed"
    exit 1
  fi
  IFS="${oldIFS}"

  BINLOGNAME=$(echo "${BINLOGNAMEARRAY[@]}" | head -n 2 | sort | head -n 1)
  mysql --protocol=tcp --host=${DB_HOST}.{{ $.Release.Namespace }} --port=${MYSQL_PORT} --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --execute="PURGE BINARY LOGS TO '${BINLOGNAME}';" --batch --skip-column-names | sort --key=1 --reverse | awk '{print $1}'
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "binlog file purge failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "purging binlog files on ${DB_HOST} before '${BINLOGNAME}' done"
}

function querybinlogposition {
  local DB_HOST=${1}
  local BINLOGPOSITION

  BINLOGPOSITION=$(mysql --protocol=tcp --host=${DB_HOST}.{{ $.Release.Namespace }} --port=${MYSQL_PORT} --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} --execute="SELECT VARIABLE_VALUE FROM information_schema.GLOBAL_STATUS where variable_name like 'BINLOG_SNAPSHOT_POSITION';" --batch --skip-column-names)
  if [ $? -ne 0 ]; then
    exit 1
  fi
  echo ${BINLOGPOSITION}
}

function expirekopiabackups {
  local KOPIA_SNAPSHOT_PATH
  loginfo "${FUNCNAME[0]}" "remove old kopia snapshots if required"

  if [ "${MARIADB_BACKUP_TYPE}" == "full" ]; then
    KOPIA_SNAPSHOT_PATH="kopia@backup-kopia:/mariadb.full"
  elif [ "${MARIADB_BACKUP_TYPE}" == "binlog" ]; then
    KOPIA_SNAPSHOT_PATH="kopia@backup-kopia:/opt/kopia/var/tmp/binlog"
  fi

  kopia snapshot expire ${KOPIA_SNAPSHOT_PATH} \
                --delete \
                --progress-update-interval={{ $.Values.mariadb.galera.backup.kopia.progressUpdateInterval | default "300ms" | quote }}

  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "kopia snapshot removal failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "kopia snapshot removal done"
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
