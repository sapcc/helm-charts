{{- define "external.receiver" }} # input
webhookevent/external-alert:
  endpoint: "0.0.0.0:{{.Values.openTelemetryPlugin.openTelemetry.logsCollector.externalConfig.alertmanager_port}}"

tcplog/external-deployments:
  listen_address: "0.0.0.0:{{.Values.openTelemetryPlugin.openTelemetry.logsCollector.externalConfig.deployments_port}}"
  operators:
  - id: type
    type: add
    field: attributes["log.type"]
    value: "deployment"
{{- end }}

{{- define "external.transform" }}
transform/external-alert:
  error_mode: ignore
  log_statements:
    - context: log
      statements:
        - merge_maps(attributes, ParseJSON(body), "upsert")
        - set(attributes["log.type"], "alert")
        - set(time_unix_nano, observed_time_unix_nano)

transform/external-deployments:
  error_mode: ignore
  #log_statements:
  #  - context: log
  #    conditions:
  #      - resource.attributes["log.type"] == "deployment"
{{- end }}


{{- define "external.exporter" }}
opensearch/failover_a_external_alerts:
  http:
    auth:
      authenticator: basicauth/failover_a
    endpoint: {{ .Values.openTelemetryPlugin.openTelemetry.openSearchLogs.endpoint }}
  logs_index: alerts-datastream
opensearch/failover_b_external_alerts:
  http:
    auth:
      authenticator: basicauth/failover_b
    endpoint: {{ .Values.openTelemetryPlugin.openTelemetry.openSearchLogs.endpoint }}
  logs_index: alerts-datastream

opensearch/failover_a_external_deployments:
  http:
    auth:
      authenticator: basicauth/failover_a
    endpoint: {{ .Values.openTelemetryPlugin.openTelemetry.openSearchLogs.endpoint }}
  logs_index: deployments-datastream
opensearch/failover_b_external_deployments:
  http:
    auth:
      authenticator: basicauth/failover_b
    endpoint: {{ .Values.openTelemetryPlugin.openTelemetry.openSearchLogs.endpoint }}
  logs_index: deployments-datastream
  
{{- end }}



{{- define "external.connectors" }}
forward/external_alerts: {}
forward/external_deployments: {}
failover/opensearch_external_alerts:
  priority_levels:
    - [logs/failover_a_external_alerts]
    - [logs/failover_b_external_alerts]
  retry_interval: 1h
  retry_gap: 15m
  max_retries: 0

failover/opensearch_external_deployments:
  priority_levels:
    - [logs/failover_a_external_deployments]
    - [logs/failover_b_external_deployments]
  retry_interval: 1h
  retry_gap: 15m
  max_retries: 0
{{ end }}
{{- define "external.pipeline" }}

logs/forward_external:
  receivers: [forward/external]
  processors: [batch]
  exporters: [failover/opensearch_external]

logs/failover_a_external_alerts:
  receivers: [failover/opensearch_external]
  processors: [attributes/failover_username_a]
  exporters: [opensearch/failover_a_external_alerts]
logs/failover_b_external_alerts:
  receivers: [failover/opensearch_external]
  processors: [attributes/failover_username_b]
  exporters: [opensearch/failover_b_external_alerts]
  
logs/failover_a_external_deployments:
  receivers: [failover/opensearch_external]
  processors: [attributes/failover_username_a]
  exporters: [opensearch/failover_a_external_deployments]
logs/failover_b_external_deployments:
  receivers: [failover/opensearch_external]
  processors: [attributes/failover_username_b]
  exporters: [opensearch/failover_b_external_deployments]

logs/external-alerts:
  receivers: [webhookevent/external-alert]
  processors: [transform/external-alert]
  exporters: [debug,forward/external_alerts]

logs/external-deployments:
  receivers: [tcplog/external-deployments]
  processors: [transform/external-deployments]
  exporters: [forward/external_deployments]
{{- end }}
