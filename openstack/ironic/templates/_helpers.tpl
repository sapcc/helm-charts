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
