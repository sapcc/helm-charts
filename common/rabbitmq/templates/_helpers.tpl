{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{define "rabbitmq.release_host"}}{{.Release.Name}}-rabbitmq.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{- define "rabbitmq.transport_url" -}}{{ tuple . .Values.rabbitmq | include "rabbitmq._transport_url" }}{{- end}}

{{- define "rabbitmq._transport_url" -}}
{{- $envAll := index . 0 -}}
{{- $rabbitmq := index . 1 -}}
rabbit://{{ default "" $envAll.Values.global.user_suffix | print $rabbitmq.users.default.user }}:{{ $rabbitmq.users.default.password | default (tuple $envAll $rabbitmq.users.default.user | include "rabbitmq.password_for_user")  | urlquery}}@{{ include "rabbitmq.release_host" $envAll }}:{{ $rabbitmq.port | default 5672 }}{{ $rabbitmq.virtual_host | default "/" }}
{{- end}}

{{- define "rabbitmq.password_for_fixed_user_and_host" }}
    {{- $envAll := index . 0 }}
    {{- $user := index . 1 }}
    {{- $host := index . 2 }}
    {{- derivePassword 1 "long" $envAll.Values.global.master_password $user $host }}
{{- end }}

{{- define "rabbitmq.password_for_fixed_user"}}
    {{- $envAll := index . 0 }}
    {{- $user := index . 1 }}
    {{- tuple $envAll $user ( include "rabbitmq.release_host" $envAll ) | include "rabbitmq.password_for_fixed_user_and_host" }}
{{- end }}

{{- define "rabbitmq.password_for_user"}}
    {{- $envAll := index . 0 }}
    {{- $user := index . 1 }}
    {{- tuple $envAll ( $envAll.Values.global.user_suffix | default "" | print $user ) | include "rabbitmq.password_for_fixed_user" }}
{{- end }}

{{- define "rabbitmq.shell_quote" -}}
"{{- replace `"` `\"`  . | replace `$` `\$` | replace "`" (print `\` "`") -}}"
{{- end }}

{{/* Generate the service label for the templated Prometheus alerts. */}}
{{- define "alerts.service" -}}
{{- if .Values.alerts.service -}}
{{- .Values.alerts.service -}}
{{- else -}}
{{- .Release.Name -}}
{{- end -}}
{{- end -}}
