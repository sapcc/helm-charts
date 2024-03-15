#!/usr/bin/env bash

set -e

. /container.init/common.sh

manila-status --config-file /etc/manila/manila.conf --config-file /etc/manila/manila.conf.d/secrets.conf upgrade check
manila-manage db sync
manila-manage service cleanup
{{ include "utils.proxysql.proxysql_signal_stop_script" . }}
