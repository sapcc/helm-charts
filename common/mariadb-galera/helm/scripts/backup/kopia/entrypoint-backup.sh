#!/usr/bin/env bash
set +e
set -u
set -o pipefail

rm -f /tmp/nodelist.seqno
source /opt/${SOFTWARE_NAME}/bin/common-functions.sh

function setkopiapolicy {
  loginfo "${FUNCNAME[0]}" "configure kopia snapshot policy"
  kopia policy set --global \
          --keep-latest {{ $.Values.mariadb.galera.backup.kopia.keep.last | default 2 | int }} \
          --keep-hourly {{ $.Values.mariadb.galera.backup.kopia.keep.hourly | default 24 | int }} \
          --keep-daily {{ $.Values.mariadb.galera.backup.kopia.keep.daily | default 1 | int }} \
          --keep-weekly {{ $.Values.mariadb.galera.backup.kopia.keep.weekly | default 0 | int }} \
          --keep-monthly {{ $.Values.mariadb.galera.backup.kopia.keep.monthly | default 0 | int }} \
          --keep-annual {{ $.Values.mariadb.galera.backup.kopia.keep.yearly | default 0 | int }} \
          --progress-update-interval={{ $.Values.mariadb.galera.backup.kopia.progressUpdateInterval | default "300ms" | quote }}
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "kopia snapshot policy config failed"
    exit 1
  else
    loginfo "${FUNCNAME[0]}" "kopia snapshot policy config done"
  fi
}

function createkopiadbbackup {
  if [ "${MARIADB_BACKUP_TYPE}" == "full" ]; then
    local DB_HOST=${1}
    local SEQNO=${2}
    local BINLOGNAME=$(queryoldestbinlogname ${DB_HOST})
    local BINLOGPOSITION=$(querybinlogposition ${DB_HOST})

    loginfo "${FUNCNAME[0]}" "mariadb-dump using ${DB_HOST} started"
    mariadb-dump --protocol=tcp --host=${DB_HOST}.{{ $.Release.Namespace }} --port=${MYSQL_PORT} \
                --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} \
                --all-databases --add-drop-database --flush-privileges --flush-logs --hex-blob --events --routines --comments --triggers --skip-log-queries \
                --gtid --master-data=1 --single-transaction | \
    kopia snapshot create /mariadb.${MARIADB_BACKUP_TYPE} --stdin-file=dump.sql \
                  --tags=mariadb.version:${MARIADB_VERSION} \
                  --tags=mariadb.cluster:${MARIADB_CLUSTER_NAME} \
                  --tags=mariadb.seqno:${SEQNO} \
                  --tags=mariadb.binlogsnapshotfile:${BINLOGNAME} \
                  --tags=mariadb.binlogposition:${BINLOGPOSITION} \
                  --tags=backup.type:dump \
                  --progress-update-interval={{ $.Values.mariadb.galera.backup.kopia.progressUpdateInterval | default "300ms" | quote }} \
                  --json --json-indent
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "mariadb-dump failed"
      exit 1
    fi
    loginfo "${FUNCNAME[0]}" "mariadb-dump done"
    {{- if $.Values.mariadb.galera.backup.kopia.purgeBinlogsAfterFullBackup }}
    purgebinlogfiles ${DB_HOST}
    {{- end }}
  fi
}

function createkopiabinlogbackup {
  if [ "${MARIADB_BACKUP_TYPE}" == "binlog" ]; then
    local DB_HOST=${1}
    local SEQNO=${2}
    local BINLOGNAME=$(queryoldestbinlogname ${DB_HOST})
    local BINLOGPOSITION=$(querybinlogposition ${DB_HOST})

    cd /opt/${SOFTWARE_NAME}/var/tmp/binlog

    loginfo "${FUNCNAME[0]}" "mariadb-binlog using ${BINLOGNAME} and newer from ${DB_HOST} started"
    mariadb-binlog --protocol=tcp --host=${DB_HOST}.{{ $.Release.Namespace }} --port=${MYSQL_PORT} \
                --user=${MARIADB_ROOT_USERNAME} --password=${MARIADB_ROOT_PASSWORD} \
                --raw --read-from-remote-server \
                --to-last-log --verify-binlog-checksum ${BINLOGNAME}
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "mariadb-binlog failed"
      exit 1
    fi

    kopia snapshot create \
                  --tags=mariadb.version:${MARIADB_VERSION} \
                  --tags=mariadb.cluster:${MARIADB_CLUSTER_NAME} \
                  --tags=mariadb.seqno:${SEQNO} \
                  --tags=mariadb.binlogsnapshotfile:${BINLOGNAME} \
                  --tags=mariadb.binlogposition:${BINLOGPOSITION} \
                  --tags=backup.type:binlog \
                  --progress-update-interval={{ $.Values.mariadb.galera.backup.kopia.progressUpdateInterval | default "300ms" | quote }} \
                  --json --json-indent \
                  /opt/${SOFTWARE_NAME}/var/tmp/binlog
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "kopia snapshot creation failed"
      exit 1
    fi
    cd ${HOME}
    loginfo "${FUNCNAME[0]}" "mariadb-binlog done"
  fi
}

{{- range $int, $err := until ((include "replicaCount" (dict "global" $ "type" "database")) | int) }}
fetchseqnofromremotenode {{ (printf "%s-%d" (include "nodeNamePrefix" (dict "global" $ "component" "database")) $int) }} >>/tmp/nodelist.seqno
{{- end }}
selectbackupnode
initkopiarepo
setkopiapolicy
setclusterdesyncmode ${NODENAME[0]} ON
createkopiadbbackup ${NODENAME[0]} ${NODENAME[1]}
createkopiabinlogbackup ${NODENAME[0]} ${NODENAME[1]}
setclusterdesyncmode ${NODENAME[0]} OFF
{{- if $.Values.mariadb.galera.backup.kopia.expireBackups }}
expirekopiabackups
{{- end }}
{{- if $.Values.mariadb.galera.backup.kopia.listBackups }}
listkopiabackups
{{- end }}
