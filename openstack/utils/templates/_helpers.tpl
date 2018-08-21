{{- define "joinKey" -}}
{{ range $item, $_ := . -}}{{$item | replace "." "_" -}},{{- end }}
{{- end -}}

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
redis://:{{ $options.redis.redisPassword }}@flamegraph-redis.monsoon3.svc.kubernetes.{{ .Values.global.region }}.{{ .Values.global.tld }}:6379/0
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
    {{- end }}
{{- end }}

{{- define "osprofiler_pipe" }}
    {{- $options := merge .Values.osprofiler .Values.global.osprofiler }}
    {{- if $options.enabled }} osprofiler{{ end -}}
{{- end }}
