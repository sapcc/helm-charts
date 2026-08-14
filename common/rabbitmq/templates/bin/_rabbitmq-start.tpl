#!/usr/bin/env bash
set -euo pipefail

{{- if and .Values.metrics.enabled .Values.metrics.port }}
echo "prometheus.tcp.port = {{ .Values.metrics.port }}" >> /etc/rabbitmq/conf.d/10-defaults.conf
{{- end}}
{{- if .Values.addDevUser }}
echo "loopback_users.dev = true" >> /etc/rabbitmq/conf.d/10-defaults.conf
{{- end}}

LOCKFILE=/var/lib/rabbitmq/rabbitmq-server.lock
echo "Starting RabbitMQ with lock ${LOCKFILE}"
exec 9>${LOCKFILE}
/usr/bin/flock -n 9

rabbitmq-server &
PID=$!
function cleanup() {
    kill -SIGTERM $PID
    wait $(jobs -rp) || true
}
trap cleanup EXIT

timeout ${RABBIT_START_TIMEOUT:-60} rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit@$HOSTNAME.pid

{{- if .Values.debug }}
rabbitmq-plugins enable rabbitmq_tracing
rabbitmqctl trace_on
{{- end }}

{{- if and .Values.enableAllFeatureFlags .Values.persistence.enabled }}
rabbitmqctl enable_feature_flag all
{{- end }}

bash /container.init/rabbitmq-setup-users 2>&1

wait $(jobs -rp) || true
sleep inf
