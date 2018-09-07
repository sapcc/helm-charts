#!/usr/bin/env bash
set -e

LOCKFILE=/var/lib/rabbitmq/rabbitmq-server.lock
echo "Starting RabbitMQ with lock ${LOCKFILE}"
exec 9>${LOCKFILE}
/usr/bin/flock -n 9

function upsert_user {
    rabbitmqctl add_user "$1" "$2" || rabbitmqctl change_password "$1" "$2"
    rabbitmqctl set_permissions "$1" ".*" ".*" ".*"
    [ -z "$3" ] || rabbitmqctl set_user_tags "$1" "$3"
}

function bootstrap {
   #Not especially proud of this, but it works (unlike the environment variable approach in the docs)
   chown -R rabbitmq:rabbitmq /var/lib/rabbitmq

   /etc/init.d/rabbitmq-server start || ( cat /var/log/rabbitmq/startup_* && exit 1 )

{{- if .Values.debug }}
   rabbitmq-plugins enable rabbitmq_tracing
   rabbitmqctl trace_on
{{- end }}

   upsert_user {{ .Values.users.default.user }} {{ .Values.users.default.password | default (tuple . .Values.users.default.user | include "rabbitmq.password_for_user") | replace "$" "\\$" | quote }}

   upsert_user {{ .Values.users.admin.user }} {{ .Values.users.admin.password | default (tuple . .Values.users.admin.user | include "rabbitmq.password_for_user") | replace "$" "\\$" | quote }} administrator

{{- if .Values.metrics.enabled }}
   upsert_user {{ .Values.metrics.user }} {{ .Values.metrics.password | default (tuple . .Values.metrics.user | include "rabbitmq.password_for_user") | replace "$" "\\$" | quote }} monitoring
{{- end }}

   rabbitmqctl change_password guest {{ .Values.users.default.password | default (tuple . .Values.users.default.user | include "rabbitmq.password_for_user") | replace "$" "\\$" | quote }} || true
   rabbitmqctl set_user_tags guest monitoring || true
   /etc/init.d/rabbitmq-server stop
}


function start_application {
  exec gosu rabbitmq rabbitmq-server
}

bootstrap
start_application
