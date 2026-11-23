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

{{/* Keep the original pin for images; extract metadata only when naming Jobs. */}}
{{- define "glance.image.tag" -}}
{{- first (splitList "@" (toString .)) -}}
{{- end -}}

{{- define "glance.image.digest" -}}
{{- $parts := splitList "@" (toString .) -}}
{{- if gt (len $parts) 1 -}}{{- index $parts 1 -}}{{- end -}}
{{- end -}}

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $pin := .Values.imageVersion | required "Please set glance.imageVersion or similar" }}
    {{- $tag := include "glance.image.tag" $pin }}
    {{- $digest := include "glance.image.digest" $pin }}
    {{- $bin := include "utils.proxysql.proxysql_signal_stop_script" . | trim }}
    {{- $all := list $bin (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container") (include "utils.trust_bundle.volume_mount" . ) (include "utils.trust_bundle.volumes" . ) (include "utils.trust_bundle.env" . )  | join "\n" }}
    {{- $hashInput := empty .Values.proxysql.mode | ternary $bin $all }}
    {{- if $digest }}{{- $hashInput = printf "%s\n%s" $hashInput $digest }}{{- end }}
    {{- $hash := $hashInput | sha256sum }}
    {{- if $digest }}
      {{- /* Budget the readable prefix, retaining the Job kind and rotating hash. */ -}}
      {{- $suffix := printf "-%s-%s" $name (substr 0 4 $hash) }}
      {{- $prefix := regexReplaceAll "[^a-z0-9-]+" (printf "%s-%s" .Release.Name $tag | lower) "-" | trimAll "-" }}
      {{- printf "%s%s" ($prefix | trunc (int (sub 63 (len $suffix))) | trimSuffix "-") $suffix }}
    {{- else }}
      {{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ $tag }}
    {{- end }}
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
