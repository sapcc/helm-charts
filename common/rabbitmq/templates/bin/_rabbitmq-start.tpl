#!/usr/bin/env bash
set -e

LOCKFILE=/var/lib/rabbitmq/rabbitmq-server.lock
echo "Starting RabbitMQ with lock ${LOCKFILE}"
exec 9>${LOCKFILE}
/usr/bin/flock -n 9

declare -A users

function upsert_user {
    if [ ${users[$1]+_} ]; then
        rabbitmqctl change_password "$1" "$2"
        if [ -z "$3" ]; then
            [ -z ${users[$1]} ] || rabbitmqctl set_user_tags "$1"
        else
            [ "${users[$1]}" == "$3" ] || rabbitmqctl set_user_tags "$1" "$3"
        fi
    else
        rabbitmqctl add_user "$1" "$2"
        rabbitmqctl set_permissions "$1" ".*" ".*" ".*"
        [ -z "$3" ] || rabbitmqctl set_user_tags "$1" "$3"
    fi
}

function bootstrap {
   #Not especially proud of this, but it works (unlike the environment variable approach in the docs)
   chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

   /etc/init.d/rabbitmq-server start || ( cat /var/log/rabbitmq/startup_* && exit 1 )

{{- if .Values.debug }}
   rabbitmq-plugins enable rabbitmq_tracing
   rabbitmqctl trace_on
{{- end }}
   rabbitmqctl list_users -q | awk '{printf "users[\"%s\"]=\"%s\"\n", $1, substr($2, 2, length($2)-2)}' | eval

   upsert_user {{ .Values.users.default.user | include "rabbitmq.shell_quote" }} {{ required ".Values.users.default.password missing" .Values.users.default.password | include "rabbitmq.shell_quote" }}
   upsert_user {{ .Values.users.admin.user | include "rabbitmq.shell_quote" }} {{ required ".Values.users.admin.password missing" .Values.users.admin.password | include "rabbitmq.shell_quote" }} administrator

{{- if .Values.metrics.enabled }}
   upsert_user {{ .Values.metrics.user | include "rabbitmq.shell_quote" }} {{ required ".Values.metrics.password missing" .Values.metrics.password | include "rabbitmq.shell_quote" }} monitoring
{{- end }}

   upsert_user guest {{ required ".Values.users.default.password missing" .Values.users.default.password | include "rabbitmq.shell_quote" }} monitoring || true
   /etc/init.d/rabbitmq-server stop
}


function start_application {
  exec gosu rabbitmq rabbitmq-server
}

bootstrap
start_application
