#!/usr/bin/env bash
set -exuo pipefail

LOCKFILE=/var/lib/rabbitmq/rabbitmq-server.lock
echo "Starting RabbitMQ with lock ${LOCKFILE}"
exec 9>${LOCKFILE}
/usr/bin/flock -n 9

declare -A users

function upsert_user {
    if [ "${users[$1]+set}" ]; then
        rabbitmqctl -q change_password "$1" "$2"
        if [ "${3+set}" ]; then
            [ "${users[$1]}" == "${3}" ] || rabbitmqctl -q set_user_tags "$1" "$3"
        elif [ "${users[$1]+set}" ]; then
            rabbitmqctl -q set_user_tags "$1"
        fi
    else
        rabbitmqctl -q add_user "$1" "$2"
        rabbitmqctl -q set_permissions "$1" ".*" ".*" ".*"
        if [ "${3+set}" ]; then
            rabbitmqctl -q set_user_tags "$1" "$3"
        else
            rabbitmqctl -q set_user_tags "$1"
        fi
    fi
}

rabbitmq-server &
PID=$!
function cleanup() {
    kill -SIGTERM $PID
    wait $(jobs -rp) || true
}
trap cleanup EXIT

timeout 60 rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit@$HOSTNAME.pid

{{- if .Values.debug }}
rabbitmq-plugins enable rabbitmq_tracing
rabbitmqctl trace_on
{{- end }}

eval $(timeout 5.0 rabbitmqctl list_users -q | awk '{printf "users[\"%s\"]=\"%s\"\n", $1, substr($2, 2, length($2)-2)}')

{{- range $k, $v := .Values.users }}
upsert_user {{ $v.user | include "rabbitmq.shell_quote" }} {{ required (printf ".Values.users.%v.password missing" $k) $v.password | include "rabbitmq.shell_quote" }}{{ if $v.tag }} {{ $v.tag | include "rabbitmq.shell_quote" }}{{ end }}
{{- end }}
{{- if .Values.metrics.enabled }}
upsert_user {{ .Values.metrics.user | include "rabbitmq.shell_quote" }} {{ required ".Values.metrics.password missing" .Values.metrics.password | include "rabbitmq.shell_quote" }} monitoring
{{- end }}
upsert_user guest {{ required ".Values.users.default.password missing" .Values.users.default.password | include "rabbitmq.shell_quote" }} monitoring

wait $(jobs -rp) || true
sleep inf
