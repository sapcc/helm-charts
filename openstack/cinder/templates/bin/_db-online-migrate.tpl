#!/usr/bin/env bash
set -euxo pipefail

cinder-manage db online_data_migrations

{{ include "utils.script.job_finished_hook" . }}
