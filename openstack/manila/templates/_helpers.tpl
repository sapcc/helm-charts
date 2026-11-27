{{- define "manila_type_seed.specs" }}
driver_handles_share_servers: true
snapshot_support: true
{{- end }}

{{/*
Define the Manila API dependency services for kubernetes-entrypoint init container
memcached is being used only by API via keystoneauth
*/}}
{{- define "manila.api_service_dependencies" }}
  {{- template "manila.db_service" . }},{{ template "manila.rabbitmq_service" . }},{{ template "manila.memcached_service" . }}
{{- end }}

{{/*
Define the Manila dependency services for kubernetes-entrypoint init container
*/}}
{{- define "manila.service_dependencies" }}
  {{- template "manila.db_service" . }},{{ template "manila.rabbitmq_service" . }}
{{- end }}

{{- define "manila.db_service" }}
  {{- include "utils.db_host" . }}
{{- end }}

{{- define "manila.rabbitmq_service" }}
  {{- .Release.Name }}-rabbitmq
{{- end }}

{{- define "manila.memcached_service" }}
  {{- .Release.Name }}-memcached
{{- end }}

{{/* Keep the original pin for images; extract metadata only when naming Jobs. */}}
{{- define "manila.image.tag" -}}
{{- first (splitList "@" (toString .)) -}}
{{- end -}}

{{- define "manila.image.digest" -}}
{{- $parts := splitList "@" (toString .) -}}
{{- if gt (len $parts) 1 -}}{{- index $parts 1 -}}{{- end -}}
{{- end -}}

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $pin := .Values.loci.imageVersion | required "Please set manila.loci.imageVersion" }}
    {{- $tag := include "manila.image.tag" $pin }}
    {{- $digest := include "manila.image.digest" $pin }}
    {{- $bin := include (print .Template.BasePath "/bin/_db_migrate.sh.tpl") . }}
    {{- $all := list $bin
          (include (print .Template.BasePath "/etc-configmap.yaml") .)
          (include (print .Template.BasePath "/secrets.yaml") .)
          (include "utils.proxysql.job_pod_settings" .)
          (include "utils.proxysql.volume_mount" .)
          (include "utils.proxysql.container" .)
          (include "utils.proxysql.volumes" .)
          (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container")
      | join "\n" }}
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

{{- define "manila.reloader.secrets" -}}
{{- $ctx := .ctx -}}
{{- $names := list (printf "%s-secrets" $ctx.Release.Name) -}}
{{- if $ctx.Values.proxysql.mode -}}
{{- $names = append $names (printf "%s-proxysql-etc" $ctx.Release.Name) -}}
{{- end -}}
{{- $names | join "," -}}
{{- end }}
