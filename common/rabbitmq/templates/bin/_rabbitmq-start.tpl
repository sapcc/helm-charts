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

   upsert_user {{ .Values.users.default.user | include "rabbitmq.shell_quote" }} {{ required ".Values.users.default.password missing" .Values.users.default.password | include "rabbitmq.shell_quote" }}

   upsert_user {{ .Values.users.admin.user | include "rabbitmq.shell_quote" }} {{ required ".Values.users.admin.password missing" .Values.users.admin.password | include "rabbitmq.shell_quote" }} administrator

{{- if .Values.metrics.enabled }}
   upsert_user {{ .Values.metrics.user | include "rabbitmq.shell_quote" }} {{ required ".Values.metrics.password missing" .Values.metrics.password | include "rabbitmq.shell_quote" }} monitoring
{{- end }}

{{- if .Values.openstack.users }}
   upsert_user {{ .Values.users.octavia | include "rabbitmq.shell_quote" }} {{ required ".Values.users.octavia missing" .Values.users.octavia.password | include "rabbitmq.shell_quote" }}
   upsert_user {{ .Values.users.barbican | include "rabbitmq.shell_quote" }} {{ required ".Values.users.barbican missing" .Values.users.barbican.password | include "rabbitmq.shell_quote" }}
   upsert_user {{ .Values.users.cinder | include "rabbitmq.shell_quote" }} {{ required ".Values.users.cinder missing" .Values.users.cinder.password | include "rabbitmq.shell_quote" }}
   upsert_user {{ .Values.users.designate | include "rabbitmq.shell_quote" }} {{ required ".Values.users.designate missing" .Values.users.designate.password | include "rabbitmq.shell_quote" }}
   upsert_user {{ .Values.users.glance | include "rabbitmq.shell_quote" }} {{ required ".Values.users.glance missing" .Values.users.glance.password | include "rabbitmq.shell_quote" }}
   upsert_user {{ .Values.users.manila | include "rabbitmq.shell_quote" }} {{ required ".Values.users.manila missing" .Values.users.manila.password | include "rabbitmq.shell_quote" }}
   upsert_user {{ .Values.users.neutron | include "rabbitmq.shell_quote" }} {{ required ".Values.users.neutron missing" .Values.users.neutron.password | include "rabbitmq.shell_quote" }}
   upsert_user {{ .Values.users.nova | include "rabbitmq.shell_quote" }} {{ required ".Values.users.nova missing" .Values.users.nova.password | include "rabbitmq.shell_quote" }}
{{- end }}

   rabbitmqctl change_password guest {{ required ".Values.users.default.password missing" .Values.users.default.password | include "rabbitmq.shell_quote" }} || true
   rabbitmqctl set_user_tags guest monitoring || true
   /etc/init.d/rabbitmq-server stop
}


function start_application {
  exec gosu rabbitmq rabbitmq-server
}

bootstrap
start_application
