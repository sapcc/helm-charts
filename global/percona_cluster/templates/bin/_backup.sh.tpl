#!/bin/bash

set -o errexit
set -o xtrace

LIB_PATH='/usr/lib/pxc'
. ${LIB_PATH}/vault.sh

GARBD_OPTS=""
SOCAT_OPTS="TCP-LISTEN:4444,reuseaddr,retry=30"
SST_INFO_NAME=sst_info

function get_backup_source() {
    CLUSTER_SIZE=1

    FIRST_NODE=$(peer-list -on-start=/usr/bin/get-pxc-state -service=$PXC_SERVICE 2>&1 \
        | grep wsrep_ready:ON:wsrep_connected:ON:wsrep_local_state_comment:Synced:wsrep_cluster_status:Primary \
        | sort -r \
        | tail -1 \
        | cut -d : -f 2 \
        | cut -d . -f 1)

    SKIP_FIRST_POD='|'
    if (( $CLUSTER_SIZE > 1 )); then
        SKIP_FIRST_POD="$FIRST_NODE"
    fi
    peer-list -on-start=/usr/bin/get-pxc-state -service=$PXC_SERVICE 2>&1 \
        | grep wsrep_ready:ON:wsrep_connected:ON:wsrep_local_state_comment:Synced:wsrep_cluster_status:Primary \
        | grep -v $SKIP_FIRST_POD \
        | sort \
        | tail -1 \
        | cut -d : -f 2 \
        | cut -d . -f 1
}

function request_streaming() {
    local LOCAL_IP=$(hostname -i)

    if [ -z "$NODE_NAME" ]; then
        peer-list -on-start=/usr/bin/get-pxc-state -service=$PXC_SERVICE
        echo "[ERROR] Cannot find node for backup"
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

    timeout -k 25 20 \
        garbd \
            --address "gcomm://$NODE_NAME?gmcast.listen_addr=tcp://0.0.0.0:4567" \
            --donor "{{ include "fullName" . }}-0-$DONOR_IP" \
            --group "$PXC_SERVICE" \
            --options "$GARBD_OPTS" \
            --sst "xtrabackup-v2:$LOCAL_IP:4444/xtrabackup_sst//1" \
            2>&1 | tee /tmp/garbd.log

    if grep 'State transfer request failed' /tmp/garbd.log; then
        exit 1
    fi
    if grep 'WARN: Protocol violation. JOIN message sender ... (garb) is not in state transfer' /tmp/garbd.log; then
        exit 1
    fi
    if grep 'WARN: Rejecting JOIN message from ... (garb): new State Transfer required.' /tmp/garbd.log; then
        exit 1
    fi
    if grep 'INFO: Shifting CLOSED -> DESTROYED (TO: -1)' /tmp/garbd.log; then
        exit 1
    fi
    if ! grep 'INFO: Sending state transfer request' /tmp/garbd.log; then
        exit 1
    fi
}

function backup_volume() {
    BACKUP_DIR=${BACKUP_DIR:-/backup/$PXC_SERVICE-$(date +%F-%H-%M)}
    mkdir -p "$BACKUP_DIR"
    cd "$BACKUP_DIR" || exit

    echo "Backup to $BACKUP_DIR started"
    request_streaming

    echo "Socat to started"

    socat -u "$SOCAT_OPTS" stdio | xbstream -x
    if [[ $? -ne 0 ]]; then
        echo "socat(1) failed"
        exit 1
    fi
    echo "socat(1) returned $?"
    vault_store $BACKUP_DIR/${SST_INFO_NAME}

    socat -u "$SOCAT_OPTS" stdio >xtrabackup.stream
    if [[ $? -ne 0 ]]; then
        echo "socat(2) failed"
        exit 1
    fi
    echo "socat(2) returned $?"

    echo "Backup finished"

    stat xtrabackup.stream
    if (( $(stat -c%s xtrabackup.stream) < 5000000 )); then
        echo empty backup
        exit 1
    fi
    md5sum xtrabackup.stream | tee md5sum.txt
}

function remove_old_backups() {
    echo "Removing backups older than $PXC_DAYS_RETENTION days..."
    find /backup/* -mtime +"$PXC_DAYS_RETENTION" -exec rm -rf {} \;
}

is_object_exist() {
    local bucket="$1"
    local object="$2"

    if [[ -n "$(mc -C /tmp/mc --json ls  "dest/$bucket/$object" | jq '.status')" ]]; then
        return 1
    fi
}

function backup_s3() {
    S3_BUCKET_PATH=${S3_BUCKET_PATH:-$PXC_SERVICE-$(date +%F-%H-%M)-xtrabackup.stream}

    echo "Backup to s3://$S3_BUCKET/$S3_BUCKET_PATH started"
    { set +x; } 2> /dev/null
    echo "+ mc -C /tmp/mc config host add dest "${ENDPOINT:-https://s3.amazonaws.com}" ACCESS_KEY_ID SECRET_ACCESS_KEY"
    mc -C /tmp/mc config host add dest "${ENDPOINT:-https://s3.amazonaws.com}" "$ACCESS_KEY_ID" "$SECRET_ACCESS_KEY"
    set -x
    is_object_exist "$S3_BUCKET" "$S3_BUCKET_PATH.$SST_INFO_NAME" || xbcloud delete --storage=s3 --s3-bucket="$S3_BUCKET" "$S3_BUCKET_PATH.$SST_INFO_NAME"
    is_object_exist "$S3_BUCKET" "$S3_BUCKET_PATH" || xbcloud delete --storage=s3 --s3-bucket="$S3_BUCKET" "$S3_BUCKET_PATH"
    request_streaming

    socat -u "$SOCAT_OPTS" stdio | xbstream -x -C /tmp
    if [[ $? -ne 0 ]]; then
        echo "socat(1) failed"
        exit 1
    fi
    vault_store /tmp/${SST_INFO_NAME}
    xbstream -C /tmp -c ${SST_INFO_NAME} \
        | xbcloud put --storage=s3 --parallel=10 --md5 --s3-bucket="$S3_BUCKET" "$S3_BUCKET_PATH.$SST_INFO_NAME" 2>&1 |
        (grep -v "error: http request failed: Couldn't resolve host name" || exit 1)
        
    socat -u "$SOCAT_OPTS" stdio |
        xbcloud put --storage=s3 --parallel=10 --md5 --s3-bucket="$S3_BUCKET" "$S3_BUCKET_PATH" 2>&1 |
        (grep -v "error: http request failed: Couldn't resolve host name" || exit 1)

    echo "Backup finished"

    mc -C /tmp/mc stat "dest/$S3_BUCKET/$S3_BUCKET_PATH.md5"
    md5_size=$(mc -C /tmp/mc stat --json "dest/$S3_BUCKET/$S3_BUCKET_PATH.md5" | sed -e 's/.*"size":\([0-9]*\).*/\1/')
    if [[ $md5_size =~ "Object does not exist" ]] || (( $md5_size < 23000 )); then
        echo empty backup
        exit 1
    fi
}

#function backup_swift() {
#    SWIFT_BUCKET_PATH=${SWIFT_BUCKET_PATH:-$PXC_SERVICE-$(date +%F-%H-%M)-xtrabackup.stream}
#
#    echo "Backup to s3://$S3_BUCKET/$SWIFT_BUCKET_PATH started"
#    { set +x; } 2> /dev/null
#    socat -u "$SOCAT_OPTS" stdio | xbstream -x -C /tmp
#    if [[ $? -ne 0 ]]; then
#        echo "socat(1) failed"
#        exit 1
#    fi
#
#    xtrabackup --backup --stream=xbstream --extra-lsndir=/tmp --target-dir=/tmp \
#        | xbcloud put --storage=swift \
#        --swift-container={{ include "fullName" . }}-backup \
#        --swift-user=test:tester \
#        --swift-key=testing \
#        --parallel=10 \
#        full_backup
#
#    echo "Backup finished"
#
#    mc -C /tmp/mc stat "dest/$S3_BUCKET/$SWIFT_BUCKET_PATH.md5"
#    md5_size=$(mc -C /tmp/mc stat --json "dest/$S3_BUCKET/$SWIFT_BUCKET_PATH.md5" | sed -e 's/.*"size":\([0-9]*\).*/\1/')
#    if [[ $md5_size =~ "Object does not exist" ]] || (( $md5_size < 23000 )); then
#        echo empty backup
#        exit 1
#    fi
#}

#get_backup_source

# backup to PVC
backup_volume

# delete old backups
remove_old_backups

if [ -n "$S3_BUCKET" ]; then
    # backup to S3
    backup_s3
fi
