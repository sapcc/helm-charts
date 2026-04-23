#!/bin/bash

set -o errexit
set -o xtrace

GARBD_OPTS="pc.weight=0"

INSECURE_ARG=""
if [ -n "$VERIFY_TLS" ] && [[ $VERIFY_TLS == "false" ]]; then
	INSECURE_ARG="--insecure"
fi

log() {
	{ set +x; } 2>/dev/null
	local level=$1
	local message=$2
	local now=$(date '+%F %H:%M:%S')

	echo "${now} [${level}] ${message}"
	set -x
}

function request_streaming() {
    local LOCAL_IP=$(hostname -i)

    if [ -z "$NODE_NAME" ]; then
        log 'ERROR' 'Cannot find node for backup'
        log 'ERROR' 'Backup was finished unsuccessfull'
        exit 1
    fi

    {{- $current_region := .Values.global.db_region -}}
    {{- $cluster_ips := values .Values.service.regions }}

    {{ range $region, $ip := .Values.service.regions -}}
    {{ if eq $region $current_region }}
    # the local donor IP is a K8s service IP, not the K8s pod IP
    DONOR_IP={{ $ip }}
    {{- end }}
    {{- end }}

    set +o errexit
    log 'INFO' 'Garbd was started'
    garbd \
        --address "gcomm://$NODE_NAME?gmcast.listen_addr=tcp://0.0.0.0:4567" \
        --donor "{{ include "fullName" . }}-0-$DONOR_IP" \
        --group "$PXC_GROUP" \
        --options "$GARBD_OPTS" \
        --sst "xtrabackup-v2:$LOCAL_IP:4444/xtrabackup_sst//1" \
        --recv-script="/startup-scripts/run_backup.sh" 2>&1 | tee /tmp/garbd.log

    if grep 'Will never receive state. Need to abort' /tmp/garbd.log; then
        exit 1
    fi

    if grep 'Donor is no longer in the cluster, interrupting script' /tmp/garbd.log; then
        exit 1
    elif grep 'failed: Invalid argument' /tmp/garbd.log; then
        exit 1
    fi

    if [ -f '/tmp/backup-is-completed' ]; then
        log 'INFO' 'Backup was finished successfully'
        exit 0
    fi

    log 'ERROR' 'Backup was finished unsuccessful'

    exit 1
}

request_streaming

exit 0
