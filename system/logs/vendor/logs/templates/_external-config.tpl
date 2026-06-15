{{/*
SPDX-FileCopyrightText: 2024 SAP SE or an SAP affiliate company and Greenhouse contributors
SPDX-License-Identifier: Apache-2.0
*/}}
{{- define "external.receiver" }}
webhookevent/external-alerts:
  endpoint: "0.0.0.0:{{.Values.openTelemetry.logsCollector.externalConfig.alertmanager_port}}"

tcplog/external-deployments:
  listen_address: "0.0.0.0:{{.Values.openTelemetry.logsCollector.externalConfig.deployments_port}}"
{{- end }}

{{- define "external.transform" }}
transform/external-alerts:
  error_mode: ignore
  log_statements:
    - context: log
      statements:
        - set(log.time_unix_nano, log.observed_time_unix_nano)
        - merge_maps(log.attributes, ParseJSON(log.body), "upsert") where IsMatch(log.body, "^\\{")
        - set(log.attributes["log.type"], "alert")

transform/external-deployments:
  error_mode: ignore
  log_statements:
    - context: log
      statements:
        - set(log.time_unix_nano, log.observed_time_unix_nano)
        - merge_maps(log.attributes, ParseJSON(log.body), "upsert") where IsMatch(log.body, "^\\{")
        - set(log.attributes["log.type"], "deployment")
{{- end }}

{{- define "external.exporter" }}
{{- if not .Values.openTelemetry.logsCollector.kafka.enabled }}
{{- range (list "alerts" "deployments") }}
opensearch/failover_a_external_{{ toString . }}:
  http:
    auth:
      authenticator: basicauth/failover_a
    endpoint: {{ $.Values.openTelemetry.openSearchLogs.endpoint }}
  logs_index: {{ toString . }}-datastream
  retry_on_failure:
    enabled: true
    initial_interval: 1s
    max_interval: 5s
    max_elapsed_time: 30s
  timeout: 10s
opensearch/failover_b_external_{{ toString . }}:
  http:
    auth:
      authenticator: basicauth/failover_b
    endpoint: {{ $.Values.openTelemetry.openSearchLogs.endpoint }}
  logs_index: {{ toString . }}-datastream
  retry_on_failure:
    enabled: true
    initial_interval: 1s
    max_interval: 5s
    max_elapsed_time: 30s
  timeout: 10s
{{- end }}
{{- end }}
{{- end }}

{{- define "external.connectors" }}
{{- if not .Values.openTelemetry.logsCollector.kafka.enabled }}
{{- range (list "alerts" "deployments") }}
failover/opensearch_external_{{ toString . }}:
  priority_levels:
    - [logs/failover_a_external_{{ toString . }}]
    - [logs/failover_b_external_{{ toString . }}]
  retry_interval: 1h
  sending_queue:
    block_on_overflow: true
    enabled: true
    num_consumers: 2
    queue_size: 10000
    sizer: requests
{{ end }}
{{- end }}
{{- end }}

{{- define "external.pipeline" }}
{{- if not .Values.openTelemetry.logsCollector.kafka.enabled }}
{{- range (list "alerts" "deployments") }}
logs/failover_a_external_{{ toString . }}:
  receivers: [failover/opensearch_external_{{ toString . }}]
  processors: [attributes/failover_username_a]
  exporters: [opensearch/failover_a_external_{{ toString . }}]

logs/failover_b_external_{{ toString . }}:
  receivers: [failover/opensearch_external_{{ toString . }}]
  processors: [attributes/failover_username_b]
  exporters: [opensearch/failover_b_external_{{ toString . }}]

{{- end }}
{{- end }}
logs/external-alerts:
  receivers: [webhookevent/external-alerts]
  processors: [transform/external-alerts, batch]
{{- if .Values.openTelemetry.logsCollector.kafka.enabled }}
  exporters: [kafka]
{{- else }}
  exporters: [failover/opensearch_external_alerts]
{{- end }}

logs/external-deployments:
  receivers: [tcplog/external-deployments]
  processors: [transform/external-deployments, batch]
{{- if .Values.openTelemetry.logsCollector.kafka.enabled }}
  exporters: [kafka]
{{- else }}
  exporters: [failover/opensearch_external_deployments]
{{- end }}
{{- end }}
