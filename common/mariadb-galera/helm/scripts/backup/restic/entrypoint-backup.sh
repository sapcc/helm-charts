#!/usr/bin/env bash
set +e
set -u
set -o pipefail

rm -f /tmp/nodelist.seqno
source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function initresticrepo {
  loginfo "${FUNCNAME[0]}" "init restic repository if required"
  restic stats --quiet --json --tag dump latest
  if [ $? -ne 0 ]; then
    loginfo "${FUNCNAME[0]}" "No restic repository found"
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

function createresticdbbackup {
  if [ "${MARIADB_BACKUP_TYPE}" == "full" ]; then
    local DB_HOST=${1}
    local SEQNO=${2}

    loginfo "${FUNCNAME[0]}" "mariadb-dump using ${DB_HOST} started"
    mariadb-dump --protocol=tcp --host=${DB_HOST}.database.svc.cluster.local --port=${MYSQL_PORT} \
                --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} \
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
  fi
}

function createresticbinlogbackup {
  if [ "${MARIADB_BACKUP_TYPE}" == "binlog" ]; then
    local DB_HOST=${1}
    local SEQNO=${2}
    local BINLOGNAME=$(queryoldestbinlogname ${DB_HOST})

    loginfo "${FUNCNAME[0]}" "mariadb-binlog using ${BINLOGNAME} and newer from ${DB_HOST} started"
    mariadb-binlog --protocol=tcp --host=${DB_HOST}.database.svc.cluster.local --port=${MYSQL_PORT} \
                  --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} \
                  --read-from-remote-server --to-last-log --verify-binlog-checksum ${BINLOGNAME} | \
    restic backup --stdin --stdin-filename=mariadb.binlog \
                  --tag "${SOFTWARE_VERSION}" --tag "${MARIADB_CLUSTER_NAME}" --tag "${SEQNO}" --tag "${BINLOGNAME}" --tag "binlog" \
                  --compression {{ $.Values.mariadb.galera.backup.restic.compression | default "auto" | quote }} \
                  --pack-size {{ $.Values.mariadb.galera.backup.restic.packsizeInMB | default 16 | int }} \
                  --json
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "mariadb-binlog failed"
      exit 1
    fi
    loginfo "${FUNCNAME[0]}" "mariadb-binlog done"
  fi
}

{{- range $int, $err := until ($.Values.replicas.application|int) }}
fetchseqnofromremotenode {{ (printf "%s-%d" (include "nodeNamePrefix" (dict "global" $ "component" "application")) $int) }} >>/tmp/nodelist.seqno
{{- end }}
selectbackupnode
{{- if $.Values.mariadb.galera.backup.restic.unlockRepo }}
unlockresticrepo
{{- end }}
initresticrepo
setclusterdesyncmode ${NODENAME[0]} ON
createresticdbbackup ${NODENAME[0]} ${NODENAME[1]}
createresticbinlogbackup ${NODENAME[0]} ${NODENAME[1]}
setclusterdesyncmode ${NODENAME[0]} OFF
{{- if $.Values.mariadb.galera.backup.restic.pruneBackups }}
pruneresticbackups
checkresticrepo
{{- end }}
{{- if $.Values.mariadb.galera.backup.restic.listBackups }}
listresticbackups
{{- end }}
