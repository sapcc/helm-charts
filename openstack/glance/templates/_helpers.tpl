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

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $bin := include "utils.proxysql.proxysql_signal_stop_script" . | trim }}
    {{- $all := list $bin (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container") (include "utils.trust_bundle.volume_mount" . ) (include "utils.trust_bundle.volumes" . ) (include "utils.trust_bundle.env" . )  | join "\n" }}
    {{- $hash := empty .Values.proxysql.mode | ternary $bin $all | sha256sum }}
{{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ .Values.imageVersion | required "Please set glance.imageVersion or similar"}}
  {{- end }}
{{- end }}

{{- define "glance.service_dependencies" }}
  {{- template "glance.db_service" . }},{{ template "glance.memcached_service" . }}
{{- end }}

{{- define "glance.db_service" }}
  {{- include "utils.db_host" . }}
{{- end }}

{{- define "glance.memcached_service" }}
  {{- .Release.Name }}-memcached
{{- end }}
