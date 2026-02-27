#!/usr/bin/env bash
set -euxo pipefail

cinder-manage db sync

{{ include "utils.script.job_finished_hook" . }}
