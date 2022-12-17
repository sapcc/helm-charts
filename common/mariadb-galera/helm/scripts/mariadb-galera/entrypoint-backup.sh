#!/usr/bin/env bash
set +e
set -u
set -o pipefail

rm -f /tmp/nodelist.seqno
source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

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

function initresticrepo {
  loginfo "${FUNCNAME[0]}" "init restic repository if required"
  restic stats --quiet --json
  if [ $? -ne 0 ]; then
    loginfo "${FUNCNAME[0]}" "No restic repository found"
    env
    restic init --repository-version 2 --json
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "restic repository initialization failed"
      exit 1
    else
      loginfo "${FUNCNAME[0]}" "restic repository initialization done"
    fi
  else
    loginfo "${FUNCNAME[0]}" "restic repository already exist"
  fi
}

function createdbbackup {
  local DB_HOST=${1}
  local SEQNO=${2}

  loginfo "${FUNCNAME[0]}" "mariadb-dump using ${DB_HOST} started"
  mariadb-dump --defaults-file=${BASE}/etc/my.cnf --protocol=tcp --host=${DB_HOST}.database.svc.cluster.local --port=${MYSQL_PORT} \
               --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} \
               --all-databases --add-drop-database --flush-privileges --flush-logs --hex-blob --events --routines --comments --triggers --skip-log-queries \
               --gtid --master-data=1 --single-transaction | \
  restic backup --stdin --stdin-filename=mariadb.dump \
                --tag "${SOFTWARE_VERSION}" --tag "${MARIADB_CLUSTER_NAME}" --tag "${SEQNO}" --tag "dump" \
                --compression {{ $.Values.mariadb.galera.backup.restic.compression | default "auto" | quote }} \
                --pack-size {{ $.Values.mariadb.galera.backup.restic.packsizeInMB | default 16 | int }} \
                --json
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "mariadb-dump failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "mariadb-dump done"
}

function queryoldestbinlogname {
  local DB_HOST=${1}
  local BINLOGNAME

  IFS=$'\t' BINLOGNAME=($(mysql --defaults-file=${BASE}/etc/my.cnf --protocol=tcp --host=${DB_HOST}.database.svc.cluster.local --port=${MYSQL_PORT} --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} --execute="SHOW GLOBAL STATUS LIKE 'Binlog_snapshot_file';" --batch --skip-column-names))
  IFS="${oldIFS}"
  if [ $? -ne 0 ]; then
    exit 1
  fi
  echo ${BINLOGNAME[1]}
}

function createbinlogbackup {
  local DB_HOST=${1}
  local SEQNO=${2}
  local BINLOGNAME=$(queryoldestbinlogname ${DB_HOST})

  loginfo "${FUNCNAME[0]}" "mariadb-binlog using ${BINLOGNAME} and newer from ${DB_HOST} started"
  mariadb-binlog --defaults-file=${BASE}/etc/my.cnf --protocol=tcp --host=${DB_HOST}.database.svc.cluster.local --port=${MYSQL_PORT} \
               --user=${MARIADB_ROOT_USER} --password=${MARIADB_ROOT_PASSWORD} \
               --read-from-remote-server --to-last-log --verify-binlog-checksum ${BINLOGNAME} | \
  restic backup --stdin --stdin-filename=mariadb.binlog \
                --tag "${SOFTWARE_VERSION}" --tag "${MARIADB_CLUSTER_NAME}" --tag "${SEQNO}" --tag "binlog" \
                --compression {{ $.Values.mariadb.galera.backup.restic.compression | default "auto" | quote }} \
                --pack-size {{ $.Values.mariadb.galera.backup.restic.packsizeInMB | default 16 | int }} \
                --json
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "mariadb-binlog failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "mariadb-binlog done"
}

{{- range $int, $err := until ($.Values.replicas.application|int) }}
fetchseqnofromremotenode {{ (printf "%s-%d" (include "nodeNamePrefix" (dict "global" $ "component" "application")) $int) }} >>/tmp/nodelist.seqno
{{- end }}
selectbackupnode
initresticrepo
{{- if $.Values.mariadb.galera.backup.restic.unlockRepo }}
unlockresticrepo
{{- end }}
setclusterdesyncmode ${NODENAME[0]} ON
createdbbackup ${NODENAME[0]} ${NODENAME[1]}
createbinlogbackup ${NODENAME[0]} ${NODENAME[1]}
setclusterdesyncmode ${NODENAME[0]} OFF
{{- if $.Values.mariadb.galera.backup.restic.pruneBackups }}
prunebackups
{{- else }}
#listbackups
{{- end }}
