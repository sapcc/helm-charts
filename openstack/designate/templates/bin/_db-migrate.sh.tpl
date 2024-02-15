#!/usr/bin/env bash
set -ex

designate-manage database sync --config-file /etc/designate/designate.conf --config-file /etc/designate/secrets.conf

{{ include "utils.proxysql.proxysql_signal_stop_script" . }}
