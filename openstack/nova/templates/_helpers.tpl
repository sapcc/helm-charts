{{- define "rabbitmq_user" -}}
  {{.Values.rabbitmq.users.default.user}}
{{- end -}}

{{- define "rabbitmq_password" -}}
  {{ .Values.rabbitmq.users.default.password | default (tuple . .Values.rabbitmq.users.default.user | include "rabbitmq.password_for_user")}}
{{- end -}}

{{- define "cell0_db_path" -}}
{{.Values.cell0dbUser}}:{{.Values.cell0dbPassword | default .Values.apidbPassword | urlquery}}@{{.Chart.Name}}-postgresql.{{include "svc_fqdn" .}}:5432/{{.Values.cell0dbName}}
{{- end -}}

{{- define "rabbit_url" -}}
  {{- $rabbitmq_host := printf "nova-rabbitmq.%s" ( include "svc_fqdn" . ) -}}
  rabbit://:{{ include "rabbitmq_password" . | urlquery}}@{{ $rabbitmq_host }}:5672/
{{- end -}}
