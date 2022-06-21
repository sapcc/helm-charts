#!/usr/bin/env bash
set -euo pipefail
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

eval $(timeout 10.0 rabbitmqctl list_users -q | awk '{printf "users[\"%s\"]=\"%s\"\n", $1, substr($2, 2, length($2)-2)}')

{{- range $k, $v := .Values.users }}
upsert_user {{ $v.user | include "rabbitmq.shell_quote" }} {{ required (printf ".Values.users.%v.password missing" $k) $v.password | include "rabbitmq.shell_quote" }}{{ if $v.tag }} {{ $v.tag | include "rabbitmq.shell_quote" }}{{ end }}
{{- end }}
{{- if .Values.metrics.enabled }}
upsert_user {{ .Values.metrics.user | include "rabbitmq.shell_quote" }} {{ required ".Values.metrics.password missing" .Values.metrics.password | include "rabbitmq.shell_quote" }} monitoring
{{- end }}
upsert_user guest {{ required ".Values.users.default.password missing" .Values.users.default.password | include "rabbitmq.shell_quote" }} monitoring
