#!/usr/bin/env bash

set -e

. /container.init/common.sh

manila-status upgrade check
manila-manage db sync
manila-manage service cleanup
{{ include "utils.script.job_finished_hook" . }}
