#!/usr/bin/env bash

set -ex

export STDOUT=${STDOUT:-/dev/stdout}

cat <(crontab -l) <(echo "{{ default "0 * * * *"  .Values.cron.cronSchedule }} . /scripts/repair_assignments > ${STDOUT} 2> ${STDOUT}") | crontab -

exec cron -f


