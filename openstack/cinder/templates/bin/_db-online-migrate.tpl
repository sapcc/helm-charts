#!/usr/bin/env bash
set -euxo pipefail

# cinder-manage has the config for the API DB via /etc/cinder/cinder.conf
cinder_manage="cinder-manage --config-file /etc/cinder/cinder.conf"

$cinder_manage db sync
$cinder_manage db online_data_migrations

{{ include "utils.script.job_finished_hook" . }}
