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

{{- define "db_host" -}}
{{- if .Values.global.clusterDomain -}}
{{.Release.Name}}-mariadb.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}
{{- else if .Values.mariadb_galera.enabled -}}
{{.Release.Name}}-mariadb.{{.Release.Namespace}}
{{- else -}}
{{.Release.Name}}-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end -}}
{{- end -}}

{{- define "memcached_host" -}}
{{- if .Values.global.clusterDomain -}}
{{.Release.Name}}-memcached.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}
{{- else if .Values.global_setup -}}
{{.Release.Name}}-memcached.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.db_region}}.{{.Values.global.tld}}
{{- else -}}
{{.Release.Name}}-memcached.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end -}}
{{- end -}}

{{- define "rabbitmq_host" -}}
{{- if .Values.global.clusterDomain -}}
{{.Release.Name}}-rabbitmq.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}
{{- else if .Values.global_setup -}}
{{.Release.Name}}-rabbitmq.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.db_region}}.{{.Values.global.tld}}
{{- else -}}
{{.Release.Name}}-rabbitmq.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end -}}
{{- end -}}

{{/*
To satisfy common/mysql_metrics :(
*/}}

{{define "keystone_db_host"}}{{- if .Values.global.clusterDomain }}{{.Release.Name}}-mariadb.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}{{.Release.Name}}-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{- end -}}{{end}}


{{- define "2faproxy.selectorLabels" -}}
app.kubernetes.io/name: 2faproxy
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "2faproxy.labels" -}}
helm.sh/chart: {{ include "name" . }}
{{ include "2faproxy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $bin := include "utils.proxysql.proxysql_signal_stop_script" . | trim }}
    {{- $all := list $bin (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) | join "\n" }}
    {{- $hash := empty .Values.proxysql.mode | ternary $bin $all | sha256sum }}
{{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ .Values.api.imageTag | required "Please set api.imageTag or similar"}}
  {{- end }}
{{- end }}