{{- define "octavia.image.tag" -}}
{{- first (splitList "@" (toString .)) -}}
{{- end -}}

{{- define "octavia.image.digest" -}}
{{- $parts := splitList "@" (toString .) -}}
{{- if gt (len $parts) 1 -}}
{{- index $parts 1 -}}
{{- end -}}
{{- end -}}

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "octavia.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "octavia.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "octavia.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "octavia.db_service" }}
  {{- include "utils.db_host" . }}
{{- end }}

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $pin := .Values.imageVersion | required "Please set octavia.imageVersion" }}
    {{- $tag := include "octavia.image.tag" $pin }}
    {{- $digest := include "octavia.image.digest" $pin }}
    {{- $all := list
          (include (print .Template.BasePath "/octavia-etc-configmap.yaml") .)
          (include (print .Template.BasePath "/secrets.yaml") .)
          (include "utils.proxysql.job_pod_settings" .)
          (include "utils.proxysql.volume_mount" .)
          (include "utils.proxysql.container" .)
          (include "utils.proxysql.volumes" .)
          (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container")
      | join "\n" }}
    {{- if $digest }}
      {{- $all = printf "%s\n%s" $all $digest }}
    {{- end }}
    {{- $hash := $all | sha256sum }}
    {{- if $digest }}
      {{- /* Budget the readable prefix first, retaining the Job-kind/hash suffix. */ -}}
      {{- $suffix := printf "-%s-%s" $name (substr 0 4 $hash) }}
      {{- $prefix := regexReplaceAll "[^a-z0-9-]" (printf "%s-%s" .Release.Name $tag | lower) "-" | trimAll "-" }}
      {{- $prefix = $prefix | trunc (int (sub 63 (len $suffix))) | trimSuffix "-" }}
      {{- printf "%s%s" $prefix $suffix }}
    {{- else }}
{{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ $tag }}
    {{- end }}
  {{- end }}
{{- end }}
