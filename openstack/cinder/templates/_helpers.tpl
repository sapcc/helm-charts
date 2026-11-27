{{- define "cinder.service_dependencies" }}
  {{- template "cinder.db_service" . }},{{ template "cinder.rabbitmq_service" . }}
{{- end }}

{{- define "cinder.scheduler_service_dependencies" }}
  {{- template "cinder.rabbitmq_service" . }},cinder-api
{{- end }}

{{- define "cinder.db_service" }}
  {{- include "utils.db_host" . }}
{{- end }}

{{- define "cinder.rabbitmq_service" }}
  {{- .Release.Name }}-rabbitmq
{{- end }}

{{- define "job_bin_path" }}
  {{- $name := index . 1 }}
  {{- $subdir := "" }}
  {{- if eq (len .) 3 }}
    {{- $subdir = index . 2 | default "" }}
    {{- if $subdir }}
      {{- $subdir = printf "%s/" $subdir }}
    {{- end }}
  {{- end }}
  {{- with index . 0 }}
    {{- printf "%s/bin/%s_%s.tpl" .Template.BasePath $subdir $name }}
  {{- end }}
{{- end }}

{{- define "job_metadata" }}
  {{- $name := index . 1 }}
  {{- $bin_subdir := "" }}
  {{- if eq (len .) 3 }}
    {{- $bin_subdir = index . 2 }}
  {{- end }}
  {{- with index . 0 }}
labels:
  alert-tier: os
  alert-service: cinder
{{ tuple . .Release.Name $name | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 2 }}
annotations:
  bin-hash: {{ include (include "job_bin_path" (tuple . $name $bin_subdir)) . | sha256sum }}
  {{- include "utils.linkerd.pod_and_service_annotation" . | indent 2 }}
  {{- end }}
{{- end }}

{{- define "cinder.image.tag" -}}
{{- first (splitList "@" (toString .)) -}}
{{- end -}}

{{- define "cinder.image.digest" -}}
{{- $parts := splitList "@" (toString .) -}}
{{- if gt (len $parts) 1 -}}{{- index $parts 1 -}}{{- end -}}
{{- end -}}

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $bin := include (print .Template.BasePath "/bin/_" $name ".tpl") . }}
    {{- $all := list $bin (include (print .Template.BasePath "/etc-configmap.yaml") .) (include (print .Template.BasePath "/secrets.yaml") .) (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container") | join "\n" }}
    {{- $pin := .Values.imageVersion | required "Please set cinder.imageVersion or similar" }}
    {{- $tag := include "cinder.image.tag" $pin }}
    {{- $digest := include "cinder.image.digest" $pin }}
    {{- $hashInput := empty .Values.proxysql.mode | ternary $bin $all }}
    {{- if $digest }}
      {{- $hashInput = printf "%s\n%s" $hashInput $digest }}
    {{- end }}
    {{- $hash := $hashInput | sha256sum }}
    {{- if $digest }}
      {{- $suffix := printf "-%s-%s" $name (substr 0 4 $hash) }}
      {{- $prefix := regexReplaceAll "[^a-z0-9-]" (printf "%s-%s" .Release.Name $tag | lower) "-" }}
      {{- printf "%s%s" ($prefix | trunc (int (sub 63 (len $suffix))) | trimAll "-") $suffix }}
    {{- else }}
      {{- printf "%s-%s-%s-%s" .Release.Name $name (substr 0 4 $hash) $tag }}
    {{- end }}
  {{- end }}
{{- end }}
