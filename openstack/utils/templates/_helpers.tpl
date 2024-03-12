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

{{- define "osprofiler" }}
{{- if .Values.osprofiler.enabled }}
[profiler]
enabled = true
connection_string = jaeger://localhost:6831
hmac_keys = {{ .Values.global.osprofiler.hmac_keys }}
trace_sqlalchemy = {{ .Values.global.osprofiler.trace_sqlalchemy }}
{{- end }}
{{- end }}

{{- define "osprofiler_pipe" }}
    {{- if .Values.osprofiler.enabled }} osprofiler{{ end -}}
{{- end }}

{{- define "jaeger_agent_sidecar" }}
{{- if .Values.osprofiler.enabled }}
- image: {{.Values.global.dockerHubMirrorAlternateRegion}}/jaegertracing/jaeger-agent:{{ .Values.global.osprofiler.jaeger.version }}
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
  args:
    - --reporter.grpc.host-port=openstack-jaeger-collector.{{ .Release.Namespace }}.svc:14250
    - --log-level=debug
{{- end }}
{{- end }}

# Place this in job scripts when your script stops normally, but not abnormally
# as this causes the side-car pod finish normally, but we need it for the re-runs
{{- define "utils.script.job_finished_hook" }}
{{- include "utils.proxysql.proxysql_signal_stop_script" . }}
{{- include "utils.linkerd.signal_stop_script" . }}
{{- end }}
