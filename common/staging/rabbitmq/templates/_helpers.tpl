{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "rabbitmq.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rabbitmq.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{define "rabbitmq.release_host"}}{{ template "rabbitmq.fullname" . }}.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

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

{{- define "rabbitmq.plugins"}}{{- join "," .Values.plugins -}}{{- end }}

{{- define "rabbitmq.shell_quote" -}}
"{{- replace `"` `\"`  . | replace `$` `\$` | replace "`" (print `\` "`") -}}"
{{- end }}

{{- define "rabbitmq.pass" }}
    {{- $envAll := index . 0 }}
    {{- $user := index . 1 }}
    {{- $pass := index . 2 | default ( tuple $envAll $user | include "rabbitmq.password_for_user" ) }}
{{- $pass -}}
{{- end }}

{{- define "rabbitmq.tags" }}
    {{- $user := index . 0 }}
    {{- if eq $user "admin" }}administrator{{- end }}
{{- end }}