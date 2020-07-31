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
    {{- else if $options.jaeger.enabled -}}
jaeger://localhost:6831
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

{{- define "jaeger_agent_sidecar" }}
{{- if hasKey .Values.osprofiler "jaeger" }}
{{- if hasKey .Values.osprofiler.jaeger "enabled" }}
{{- if .Values.osprofiler.jaeger.enabled }}
- image: jaegertracing/jaeger-agent:{{ .Values.osprofiler.jaeger.version }}
  name: jaeger-agent
  ports:
    - containerPort: 5775
      name: zk-compact-trft
      protocol: UDP
    - containerPort: 6831
      name: jg-compact-trft
      protocol: UDP
    - containerPort: 6832
      name: jg-binary-trft
      protocol: UDP
    - containerPort: 5778
      name: config-rest
      protocol: TCP
    - containerPort: 14271
      name: admin-http
      protocol: TCP
  args: ["--collector.host-port=openstack-jaeger-collector.{{ .Release.Namespace }}.svc:14267"]
{{- end }}
{{- end }}
{{- end }}
{{- end }}
