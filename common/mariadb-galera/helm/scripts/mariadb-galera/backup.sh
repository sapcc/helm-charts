#!/usr/bin/env bash
set +e
set -u
set -o pipefail

source /opt/${SOFTWARE_NAME}/bin/common-functions.sh
source /usr/bin/wsrep_sst_common

{{- if and (hasKey $.Values.mariadb.galera "backup") ($.Values.mariadb.galera.backup.enabled) }}
  {{- range $volumeMountsKey, $volumeMountsValue := $.Values.volumeMounts.application }}
    {{- if eq $volumeMountsValue.name "backup"}}
export BACKUP_DIR={{ required "$.Values.volumeMounts.application[backup].mountPath required if $.Values.mariadb.galera.backup is enabled" $volumeMountsValue.mountPath }}
    {{- end }}
  {{- end }}
{{- end }}
export BACKUP_TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S+%Z)

function createbackupfolder {
  loginfo "${FUNCNAME[0]}" "backup sub folder creation started"
  mkdir ${BACKUP_DIR}/${BACKUP_TIMESTAMP}
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "backup sub folder creation failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "backup sub folder creation done"
}

function deleteoldbackupfolder {
  local foldercount
  local foldername

  loginfo "${FUNCNAME[0]}" "backup folder cleanup started"
  foldercount=$(ls --ignore 'lost+found' ${BACKUP_DIR} | wc -l)
  if [ $foldercount -ge 2 ]; then
    foldername=$(ls --ignore 'lost+found' -rt ${BACKUP_DIR} | head -1)
    rm -rf ${BACKUP_DIR}/$foldername
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "backup folder cleanup failed"
      exit 1
    fi
    loginfo "${FUNCNAME[0]}" "backup folder ${BACKUP_DIR}/$foldername deleted"
  else
    loginfo "${FUNCNAME[0]}" "only 1 backup folder found"
  fi
  loginfo "${FUNCNAME[0]}" "backup folder cleanup done"
}

function deleteoldbackuparchive {
  local filecount
  local filename

  loginfo "${FUNCNAME[0]}" "backup archive cleanup started"
  filecount=$(ls ${BACKUP_DIR}/*.xz | wc -l)
  if [ $filecount -ge 2 ]; then
    filename=$(ls -rt ${BACKUP_DIR}/*.xz | head -1)
    rm -rf $filename
    if [ $? -ne 0 ]; then
      logerror "${FUNCNAME[0]}" "backup archive cleanup failed"
      exit 1
    fi
    loginfo "${FUNCNAME[0]}" "backup archive $filename deleted"
  else
    loginfo "${FUNCNAME[0]}" "only 1 backup archive found"
  fi
  loginfo "${FUNCNAME[0]}" "backup archive cleanup done"
}

function dobackup {
  loginfo "${FUNCNAME[0]}" "mariabackup started"
  echo "ready ${CONTAINER_IP}:{{ (include "getNetworkPort" (dict "global" $ "type" "backend" "name" "galera") | int) }}"
  mariabackup --defaults-file=${BASE}/etc/my.cnf --protocol=socket --user=${GALERA_SST_USER} --password=${GALERA_SST_PASSWORD} --backup --galera-info --target-dir=${BACKUP_DIR}/${BACKUP_TIMESTAMP}
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "mariabackup failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "mariabackup done"
}

function compressbackup {
  loginfo "${FUNCNAME[0]}" "tar archive creation started"
  tar -cJf ${BACKUP_DIR}/${BACKUP_TIMESTAMP}.tar.xz ${BACKUP_DIR}/${BACKUP_TIMESTAMP}
  if [ $? -ne 0 ]; then
    logerror "${FUNCNAME[0]}" "tar archive creation failed"
    exit 1
  fi
  loginfo "${FUNCNAME[0]}" "tar archive creation done"
}

deleteoldbackupfolder
deleteoldbackuparchive
dobackup
compressbackup
