#!/bin/bash

set -o errexit
set -o xtrace
set -m

SOCAT_OPTS="TCP-LISTEN:4444,reuseaddr,retry=30"

{{ if .Values.ssl.enabled }}
CA=/ssl/ca.crt
CERT=/ssl/tls.crt
KEY=/ssl/tls.key
SOCAT_OPTS="openssl-listen:4444,reuseaddr,cert=${CERT},key=${KEY},cafile=${CA},verify=1"
{{- end }}

log() {
	{ set +x; } 2>/dev/null
	local level=$1
	local message=$2
	local now=$(date '+%F %H:%M:%S')

	echo "${now} [${level}] ${message}"
	set -x
}

FIRST_RECEIVED=0
SST_FAILED=0
# shellcheck disable=SC2329
handle_sigterm() {
	if (($FIRST_RECEIVED == 0)); then
		pid_s=$(ps -C socat -o pid= || true)
		if [ -n "${pid_s}" ]; then
			log 'ERROR' 'SST request failed'
			SST_FAILED=1
			kill $pid_s
			exit 1
		else
			log 'INFO' 'SST request was finished'
		fi
	fi
}

backup_volume() {
	BACKUP_DIR=${BACKUP_DIR:-/backup/$PXC_SERVICE-$(date +%F-%H-%M)}
	if [ -d "$BACKUP_DIR" ]; then
		rm -rf $BACKUP_DIR/{xtrabackup.*,sst_info}
	fi

	mkdir -p "$BACKUP_DIR"
	cd "$BACKUP_DIR" || exit

	log 'INFO' "Backup to $BACKUP_DIR was started"

	socat -u "$SOCAT_OPTS" stdio | xbstream -x $XBSTREAM_EXTRA_ARGS &
	wait $!

	log 'INFO' 'Socat was started'

	FIRST_RECEIVED=1
	if [[ $? -ne 0 ]]; then
		log 'ERROR' 'Socat(1) failed'
		log 'ERROR' 'Backup was finished unsuccessfully'
		exit 1
	fi
	echo "[INFO] Socat(1) returned $?"

	if (($SST_FAILED == 0)); then
		socat -u "$SOCAT_OPTS" stdio >xtrabackup.stream
		if [[ $? -ne 0 ]]; then
			log 'ERROR' 'Socat(2) failed'
			log 'ERROR' 'Backup was finished unsuccessfully'
			exit 1
		fi
		log 'INFO' "Socat(2) returned $?"
	fi

	trap '' 15
	stat xtrabackup.stream
	if (($(stat -c%s xtrabackup.stream) < 5000000)); then
		log 'ERROR' 'Backup is empty'
		log 'ERROR' 'Backup was finished unsuccessfully'
		exit 1
	fi
	md5sum xtrabackup.stream | tee md5sum.txt
}

remove_old_backups() {
    log 'INFO' "Removing backups older than ${PXC_DAYS_RETENTION} days..."
    find /backup/* -mtime +"${PXC_DAYS_RETENTION}" -exec rm -rf {} \;
}
trap 'handle_sigterm' 15

backup_volume

if (($SST_FAILED == 0)); then
	touch /tmp/backup-is-completed
    remove_old_backups
fi

log 'INFO' 'Backup finished'
exit $SST_FAILED
