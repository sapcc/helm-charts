#!/usr/bin/env bash
set -euo pipefail

{{- if and .Values.metrics.enabled (not .Values.metrics.sidecar.enabled) .Values.metrics.port }}
echo "prometheus.tcp.port = {{ .Values.metrics.port }}" >> /etc/rabbitmq/conf.d/10-defaults.conf
{{- end}}
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

# wait for process to start booting (rabbitmqctl command fails on local Node if the preocess is not running)
until [[ $(ls -l /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid 2>/dev/null) ]] ; do sleep 1; done
rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid -q
# wait for rabbitmq to finish booting
until [[ $(rabbitmq-diagnostics is_running) ]]; do sleep 1; done

{{- if .Values.debug }}
rabbitmq-plugins enable rabbitmq_tracing
rabbitmqctl trace_on
{{- end }}

eval $(timeout 5.0 rabbitmqctl list_users -q | awk '{printf "users[\"%s\"]=\"%s\"\n", $1, substr($2, 2, length($2)-2)}')

{{- range $k, $v := .Values.users }}
{{ list (printf ".Values.users.%v" $k) $v | include "rabbitmq.upsert_user" }}
{{- end }}

{{- if and .Values.metrics.enabled (not .Values.users.metrics) }}
{{ list ".Values.metrics" .Values.metrics | include "rabbitmq.upsert_user" }} monitoring
{{- end }}
upsert_user guest {{ .Values.users.default.password | include "rabbitmq.shell_quote" }} monitoring
