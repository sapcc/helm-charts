{{- define "external.receiver" }} # input
tcplog/external-deployment:
  listen_address: "0.0.0.0:{{.Values.openTelemetryPlugin.openTelemetry.logsCollector.externalConfig.deployments_port}}"
  operators:
  - id: type
    type: add
    field: attributes["log.type"]
    value: "deployment"

webhookevent/external-alert:
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
  log_statements:
    - context: log
      statements:
        - merge_maps(attributes, ParseJSON(body), "upsert")
        - set(attributes["log.type"], "alert")
{{- end }}


{{- define "external.exporter" }}
opensearch/failover_a_external:
  http:
    auth:
      authenticator: basicauth/failover_a
    endpoint: {{ .Values.openTelemetryPlugin.openTelemetry.openSearchLogs.endpoint }}
  logs_index: ${index}-datastream
opensearch/failover_b_external:
  http:
    auth:
      authenticator: basicauth/failover_b
    endpoint: {{ .Values.openTelemetryPlugin.openTelemetry.openSearchLogs.endpoint }}
  logs_index: ${index}-datastream
{{- end }}

{{- define "external.pipeline" }}
logs/external-deployment:
  receivers: [tcplog/external-deployment]
  processors: [transform/external-deployment]
  exporters: [forward]
logs/external-alert:
  receivers: [webhookevent/external-alert]
  processors: [transform/external-alert]
  exporters: [debug,forward]

#logs/forward_external:
#  receivers: [forward/external]
#  processors: [batch]
#  exporters: [failover/opensearch]
{{- end }}
