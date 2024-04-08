{{- define "cinder.iniValues" -}}
    {{- $values := index . 1 -}}
    {{- $name := index . 0 -}}
    {{- range $key, $value := $values }}
        {{- if kindIs "string" $value }}
{{ $key }} = {{ $value | required (print "Please set the value for [" $name "]" $key) | replace "$" "$$" | quote }}
        {{- else if kindIs "map" $value }}
{{ $key }} = {{ $value | required (print "Please set the value for [" $name "]" $key) | toJson | squote }}
        {{- else }}
{{ $key }} = {{ $value | required (print "Please set the value for [" $name "]" $key) }}
        {{- end }}
    {{- end }}
{{- end }}
{{- define "volume_conf_secrets" -}}
{{- $volume := index . 2 -}}
{{- $name := index . 1 -}}
{{- with $envAll := index . 0 -}}
[backend_defaults]
{{- $backend_defaults := merge (default (dict) $volume.backend_defaults) $envAll.Values.defaults.backends.common }}
{{- tuple "backend_defaults" $backend_defaults | include "cinder.iniValues" }}

{{- end }}
{{- end }}
