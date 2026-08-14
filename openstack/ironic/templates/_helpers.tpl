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
{{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ .Values.imageVersion | required "Please set ironic.imageVersion" }}
  {{- end }}
{{- end }}
