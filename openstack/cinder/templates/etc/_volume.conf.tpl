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
{{- define "volume_conf" -}}
{{- $volume := index . 2 -}}
{{- $name := index . 1 -}}
{{- with $envAll := index . 0 -}}
[DEFAULT]
enabled_backends = {{ keys $volume.backends | sortAlpha | join ", " | quote }}

{{- range $name, $backend := $volume.backends }}
    {{- $values := merge $backend (get $envAll.Values.defaults.backends $backend.volume_driver) }}

[{{$name}}]
volume_backend_name = {{ $name | quote }}
    {{- tuple $name $values | include "cinder.iniValues" }}

{{- end }}

{{- end }}
{{- end }}
