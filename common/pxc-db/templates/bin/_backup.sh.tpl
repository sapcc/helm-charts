#!/bin/bash

set -x

export AWS_SHARED_CREDENTIALS_FILE='/tmp/aws-credfile'
export AWS_ENDPOINT_URL="${ENDPOINT}"
export AWS_REGION="${DEFAULT_REGION}"

if [ -n "$VERIFY_TLS" ] && [[ $VERIFY_TLS == "false" ]]; then
	AWS_S3_NO_VERIFY_SSL='--no-verify-ssl'
    XBCLOUD_ARGS="--insecure"
fi

is_object_exist() {
	local bucket="$1"
	local object="$2"

	aws $AWS_S3_NO_VERIFY_SSL s3api head-object  --bucket $bucket --key "$object" || NOT_EXIST=true
	if [[ -z "$NOT_EXIST" ]]; then
		return 1
	fi
}

s3_add_bucket_dest() {
	{ set +x; } 2>/dev/null
	aws configure set aws_access_key_id "$ACCESS_KEY_ID"
	aws configure set aws_secret_access_key "$SECRET_ACCESS_KEY"
	set -x
}

dump_databases() {
    { set +x; } 2>/dev/null
    mysqldump \
        --port="${PXC_NODE_PORT}" \
        --host="${PXC_NODE_NAME}" \
        --user="${PXC_USERNAME}" \
        --password="${PXC_PASS}" \
        --single-transaction \
        --quick \
        --all-databases \
        --source-data=1 > /tmp/${date}/dump.sql
    set -x
}

compress_dump() {
    tar -czPf /tmp/${date}/dump.tar.gz /tmp/${date}/dump.sql
}

date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p /tmp/${date}
touch /tmp/${date}/xtrabackup_tablespaces

dump_databases
compress_dump

xbstream --directory=/tmp/${date} -c dump.tar.gz $XBSTREAM_EXTRA_ARGS \
		| xbcloud put $XBCLOUD_ARGS --parallel="$(grep -c processor /proc/cpuinfo)" --storage=s3 --s3-bucket="$S3_BUCKET" "$S3_BUCKET_PATH/${date}" 2>&1 \
		| (grep -v "error: http request failed: Couldn't resolve host name" || exit 1)

s3_add_bucket_dest
# Remove backups older than 3 days
aws $AWS_S3_NO_VERIFY_SSL --output json s3api list-objects-v2 --delimiter '/' --bucket "$S3_BUCKET" --prefix "$S3_BUCKET_PATH/" | jq -c '.CommonPrefixes[]' | while read -r line; do
    create_date=$(echo $line | jq -r '.Prefix | split("/")[1]')
    create_date=$(date -d"$create_date" +%s)
    older_than=$(date -d"3 days ago" +%s)
    if [[ $create_date -lt $older_than ]]; then
        file_name=$(echo $line | jq -r '.Prefix | split("/")[1]')
        if [[ $file_name != "" ]]; then
            xbcloud delete $XBCLOUD_ARGS --storage=s3 --s3-bucket="$S3_BUCKET" "$S3_BUCKET_PATH/$file_name"
        fi
    fi
done

rm -fr /tmp/${date}

sleep 600
