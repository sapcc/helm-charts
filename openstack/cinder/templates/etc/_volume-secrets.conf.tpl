{{- define "cinder.SecretiniValues" -}}
    {{- $values := index . 1 -}}
    {{- $name := index . 0 -}}
    {{- range $key, $value := $values }}
        {{- if kindIs "string" $value }}
          {{- if hasPrefix "vault+kvv2://" $value }}
{{ $key }} = "{{ $value | required (print "Please set the value for [" $name "]" $key) | include "resolve_secret" }}"
          {{- else }}
{{ $key }} = {{ $value | required (print "Please set the value for [" $name "]" $key) | replace "$" "$$" | quote }}
          {{- end }}
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
{{- tuple "backend_defaults" $backend_defaults | include "cinder.SecretiniValues" }}

{{- range $name, $backend := $volume.backends }}
    {{- $values := merge $backend (get $envAll.Values.defaults.backends $backend.volume_driver) }}

[{{$name}}]
volume_backend_name = {{ $name | quote }}
    {{- tuple $name $values | include "cinder.SecretiniValues" }}

{{- end }}

{{- end }}
{{- end }}
