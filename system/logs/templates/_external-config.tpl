{{- define "external.receiver" }} # input
tcplog/external:
  listen_address: "0.0.0.0:{{.Values.openTelemetryPlugin.openTelemetry.logsCollector.externalConfig.deployments_port}}"
  #operators:
  #- id: type
  #  type: add
  #  field: attributes["log.type"]
  #  value: "deployment"

webhookevent/external:
  endpoint: "0.0.0.0:{{.Values.openTelemetryPlugin.openTelemetry.logsCollector.externalConfig.alertmanager_port}}"
{{- end }}

{{- define "external.transform" }}
transform/external-deployment:
  error_mode: ignore
  #log_statements:
  #  - context: log
  #    conditions:
  #      - resource.attributes["log.type"] == "deployment"

transform/external-alert:
  error_mode: ignore
  #log_statements:
  #  - context: log
  #    conditions:
  #      - resource.attributes["log.type"] == "alert"
{{- end }}

{{- define "external.pipeline" }}
logs/external-deployment:
  receivers: [tcplog/external]
  processors: [transform/external-deployment]
  exporters: [debug]
logs/external-alert:
  receivers: [webhookevent/external]
  processors: [transform/external-alert]
  exporters: [debug]
{{- end }}
