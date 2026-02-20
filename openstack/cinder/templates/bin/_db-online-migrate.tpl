#!/usr/bin/env bash
set -euxo pipefail

cinder_manage="cinder-manage --config-file /etc/cinder/cinder.conf --config-dir /etc/cinder/cinder.conf.d"

$cinder_manage db online_data_migrations

{{ include "utils.script.job_finished_hook" . }}
