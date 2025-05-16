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

{{- define "keystone.memcached_host" -}}
{{- if .Values.global.is_global_region -}}
{{.Release.Name}}-memcached.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.db_region}}.{{.Values.global.tld}}
{{- else -}}
{{.Release.Name}}-memcached.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end -}}
{{- end -}}

{{- define "keystone.service_dependencies" }}
  {{- template "keystone.db_service" . }},{{ template "keystone.memcached_service" . }}
{{- end }}

{{- define "keystone.db_service" }}
  {{- if or .Values.percona_cluster.enabled (eq .Values.dbType "pxc-global") }}
    {{- .Release.Name }}-percona-pxc
  {{- else }}
    {{- include "utils.db_host" . }}
  {{- end }}
{{- end }}

{{- define "keystone.memcached_service" }}
{{- .Release.Name }}-memcached
{{- end }}

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
    {{- $dbBackend := ternary "percona-pxc" "mariadb" .Values.percona_cluster.enabled }}
    {{- $standard := list $dbBackend (include (print .Template.BasePath "/configmap-bin.yaml") . | indent 4 ) (include (print .Template.BasePath "/configmap-etc.yaml") . | indent 4 )}}
    {{- $proxysql := list $bin (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) $dbBackend }}
    {{- $combined := concat $standard $proxysql }}
    {{- $hash := empty .Values.proxysql.mode | ternary $standard ($combined | join "\n") | sha256sum }}
    {{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ .Values.api.imageTag | required "Please set api.imageTag or similar"}}
  {{- end }}
{{- end }}
