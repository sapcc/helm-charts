#!/usr/bin/env bash
set -ex

designate-manage database sync

{{ include "utils.proxysql.proxysql_signal_stop_script" . }}
