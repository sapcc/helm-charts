{{- define "joinKey" -}}
{{ range $item, $_ := . -}}{{$item | replace "." "_" -}},{{- end }}
{{- end -}}

{{- define "util.helpers.valuesToIni" -}}
  {{- range $section, $values := . -}}
[{{ $section }}]
    {{- range $key, $value := $values}}
{{ $key }} = {{ $value }}
    {{- end }}

{{ end }}
{{- end }}

{{- define "loggerIni" -}}
{{ range $top_level_key, $value := . }}
[{{ $top_level_key }}]
keys={{ include "joinKey" $value | trimAll "," }}
{{range $item, $values := $value}}

[{{ $top_level_key | trimSuffix "s" }}_{{ $item | replace "." "_" }}]
{{- if and (eq $top_level_key "loggers") (ne $item "root")}}
qualname={{ $item }}
propagate=0
{{- end}}
{{- range $key, $value := $values }}
{{ $key }}={{ $value }}
{{- end }}
{{- end }}
{{ end }}
{{- end }}

{{- define "osprofiler_url" }}
    {{- $options := merge .Values.osprofiler .Values.global.osprofiler -}}
    {{- if $options.redis -}}
redis://:{{ $options.redis.redisPassword }}@flamegraph-redis.monsoon3.svc.kubernetes.{{ .Values.global.region }}.{{ .Values.global.tld }}:6379/0
    {{- else if $options.jaeger -}}
jaeger://{{ $options.jaeger.svc_name }}.{{ $options.jaeger.namespace | default "monsoon3" }}.svc.kubernetes.{{ .Values.global.region }}.{{ .Values.global.tld }}:6831
    {{- end -}}
{{- end }}

{{- define "osprofiler" }}
    {{- $options := merge .Values.osprofiler .Values.global.osprofiler }}
    {{- if $options.enabled }}

[profiler]
connection_string = {{ include "osprofiler_url" . }}
        {{- range $key, $value := $options }}
            {{- if not (kindIs "map" $value) }}
{{ $key }} = {{ $value }}
            {{- end }}
        {{- end }}
    {{- else }}
[profiler]
enabled = false
    {{- end }}
{{- end }}

{{- define "osprofiler_pipe" }}
    {{- $options := merge .Values.osprofiler .Values.global.osprofiler }}
    {{- if $options.enabled }} osprofiler{{ end -}}
{{- end }}
