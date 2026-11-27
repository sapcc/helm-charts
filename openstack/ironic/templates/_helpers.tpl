{{- define "ironic.helpers.extra_specs" }}
{{- $envAll := index . 0 }}
{{- $key :=  index . 1 }}
{{- $extraSpecs := get $envAll.Values.flavors.extra_specs $key | required (print "Please set ironic.flavors.extra_specs." $key) }}
{{- if ge (len .) 3 }}
    {{- $override := index . 2 }}
    {{- $extraSpecs = merge $override $extraSpecs }}
{{- end }}
{{- range $k, $v := $extraSpecs }}
{{ $k | quote }}: {{ $v | quote }}
{{- end }}
{{- end }}

{{- define "ironic.service_dependencies" }}
{{- include "ironic.db_service" . }},{{ include "ironic.rabbitmq_service" . -}}
{{- end }}

{{- define "ironic.db_service" }}
{{- include "utils.db_host" . }}
{{- end }}

{{- define "ironic.rabbitmq_service" -}}
ironic-rabbitmq
{{- end }}

{{/* Keep the original pin for images; extract metadata only when naming Jobs. */}}
{{- define "ironic.image.tag" -}}
{{- first (splitList "@" (toString .)) -}}
{{- end -}}

{{- define "ironic.image.digest" -}}
{{- $parts := splitList "@" (toString .) -}}
{{- if gt (len $parts) 1 -}}{{- index $parts 1 -}}{{- end -}}
{{- end -}}

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $pin := .Values.imageVersion | required "Please set ironic.imageVersion" }}
    {{- $tag := include "ironic.image.tag" $pin }}
    {{- $digest := include "ironic.image.digest" $pin }}
    {{- $all := list
          (include (print .Template.BasePath "/etc-configmap.yaml") .)
          (include (print .Template.BasePath "/secrets.yaml") .)
          (include "utils.proxysql.job_pod_settings" .)
          (include "utils.proxysql.volume_mount" .)
          (include "utils.proxysql.container" .)
          (include "utils.proxysql.volumes" .)
          (tuple . (dict) | include "utils.snippets.kubernetes_entrypoint_init_container")
      | join "\n" }}
    {{- $hashInput := empty .Values.proxysql.mode | ternary "" $all }}
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
