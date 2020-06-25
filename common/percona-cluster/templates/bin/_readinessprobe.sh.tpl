#!/bin/bash
set -e

{{- if eq .Values.service.percona.primary true }}

# A Primary Node
# The readiness check should work as default:
mysql -h 127.0.0.1 -e "SELECT 1" || exit 1

{{- else }}

# Not a Primary Node
# The readiness check should exit 0 for the first 10 min when SST might be in progress:

start_time=$(stat /proc/1/ | grep ^Change: | cut -f 2-3 -d$' ')
grace_time=$(date -d "$start_time 5 minutes")
now_time=$(date)

if [[ "$now_time" < "$grace_time" ]]; then
  # 5 minutes SST grace period, return 0
  exit 0
fi

mysql -h 127.0.0.1 -e "SELECT 1" || exit 1

{{- end }}
