{{- define "external.receiver" }} # input
tcplog/external:
  listen_address: "0.0.0.0:{{.Values.input.deployments_port}}"
  operators:
  - id: type
    type: add
    field: attributes["log.type"]
    value: "deployment"

{{- end }}

{{- define "external.transform" }}
transform/external:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["log.type"] == "deployment"
{{- end }}

{{- define "external.pipeline" }}
logs/containerd-swift:
  receivers: [tcplog/external]
  processors: [transform/external]
  exporters: [forward]
{{- end }}
