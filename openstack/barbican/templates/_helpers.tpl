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

{{- define "barbican.db_service" }}
  {{- include "utils.db_host" . }}
{{- end }}

{{- define "barbican.service_dependencies" }}
  {{- template "barbican.db_service" . }}
{{- end }}

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $all := list
          (include (print .Template.BasePath "/etc-configmap.yaml") .)
          (include (print .Template.BasePath "/secrets.yaml") .)
          (include "utils.proxysql.job_pod_settings" .)
          (include "utils.proxysql.volume_mount" .)
          (include "utils.proxysql.container" .)
          (include "utils.proxysql.volumes" .)
          (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container")
      | join "\n" }}
    {{- $hash := empty .Values.proxysql.mode | ternary "" $all | sha256sum }}
{{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ .Values.imageVersionBarbicanApi | required "Please set barbican.imageVersionBarbicanApi" }}
  {{- end }}
{{- end }}
