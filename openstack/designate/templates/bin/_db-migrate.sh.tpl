#!/usr/bin/env bash
set -ex

designate-manage --config-file /etc/designate/designate.conf --config-file /etc/designate/secrets.conf database sync

{{ include "utils.proxysql.proxysql_signal_stop_script" . }}
