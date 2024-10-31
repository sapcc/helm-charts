{{- define "neutron.helpers.default_transport_url" }}
{{- $data := merge (pick .Values.rabbitmq "nameOverride" "host" "port" "virtual_host") .Values.rabbitmq.users.default }}
{{- $_ := required ".Values.rabbitmq.users.default.user is required" .Values.rabbitmq.users.default.user }}
{{- $data := required ".Values.rabbitmq.users.default.password is required" .Values.rabbitmq.users.default.password | set $data "password" }}
transport_url = {{ include "utils.rabbitmq_url" (tuple . $data) }}
{{- end }}
