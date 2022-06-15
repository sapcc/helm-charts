#!/usr/bin/env bash
set -e

function upsert_user {
    rabbitmqctl add_user "$1" "$2" || rabbitmqctl change_password "$1" "$2"
    rabbitmqctl set_permissions "$1" ".*" ".*" ".*"
    [ -z "$3" ] || rabbitmqctl set_user_tags "$1" "$3"
}

function bootstrap {

{{- if .Values.debug }}
   rabbitmq-plugins enable rabbitmq_tracing
   rabbitmqctl trace_on
{{- end }}

   upsert_user {{ .Values.users.default.user | include "rabbitmq.shell_quote" }} {{ required ".Values.users.default.password missing" .Values.users.default.password | include "rabbitmq.shell_quote" }}

   upsert_user {{ .Values.users.admin.user | include "rabbitmq.shell_quote" }} {{ required ".Values.users.admin.password missing" .Values.users.admin.password | include "rabbitmq.shell_quote" }} administrator

{{- if .Values.metrics.enabled }}
   upsert_user {{ .Values.metrics.user | include "rabbitmq.shell_quote" }} {{ required ".Values.metrics.password missing" .Values.metrics.password | include "rabbitmq.shell_quote" }} monitoring
{{- end }}

   rabbitmqctl change_password guest {{ required ".Values.users.default.password missing" .Values.users.default.password | include "rabbitmq.shell_quote" }} || true
   rabbitmqctl set_user_tags guest monitoring || true
}

function waiting_for_rabbitmq {
  # wait for process to start booting (rabbitmqctl command fails on local Node if the preocess is not running)
  until [[ $(ls -l /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid 2>/dev/null) ]] ; do sleep 1; done
  rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid -q
  # wait for rabbitmq to finish booting
  until [[ $(rabbitmq-diagnostics is_running) ]]; do sleep 1; done

}

waiting_for_rabbitmq
bootstrap
