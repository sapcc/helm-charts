{{/*
SPDX-FileCopyrightText: 2024 SAP SE or an SAP affiliate company and Greenhouse contributors
SPDX-License-Identifier: Apache-2.0
*/}}
{{- define "traces.receiver" }}
otlp/traces:
  protocols:
    grpc:
      endpoint: "0.0.0.0:{{.Values.openTelemetry.externalCollector.tracesConfig.otlp_grpc_port}}"
    http:
      endpoint: "0.0.0.0:{{.Values.openTelemetry.externalCollector.tracesConfig.otlp_http_port}}"
{{- end }}

{{- define "traces.exporter" }}
{{- if not .Values.openTelemetry.kafka.enabled }}
opensearch/failover_a_traces:
  http:
    auth:
      authenticator: basicauth/failover_a
    endpoint: {{ $.Values.openTelemetry.openSearchLogs.endpoint }}
  traces_index: traces-datastream
  retry_on_failure:
    enabled: true
    initial_interval: 1s
    max_interval: 5s
    max_elapsed_time: 30s
  timeout: 30s
opensearch/failover_b_traces:
  http:
    auth:
      authenticator: basicauth/failover_b
    endpoint: {{ $.Values.openTelemetry.openSearchLogs.endpoint }}
  traces_index: traces-datastream
  retry_on_failure:
    enabled: true
    initial_interval: 1s
    max_interval: 5s
    max_elapsed_time: 30s
  timeout: 30s
{{- end }}
{{- end }}

{{- define "traces.connectors" }}
{{- if not .Values.openTelemetry.kafka.enabled }}
failover/opensearch_traces:
  priority_levels:
    - [traces/failover_a]
    - [traces/failover_b]
  retry_interval: 20m
  sending_queue:
    block_on_overflow: true
    enabled: true
    num_consumers: 2
    queue_size: 10000
    sizer: requests
{{- end }}
{{- end }}

{{- define "traces.pipeline" }}
traces/ingest:
  receivers: [otlp/traces]
  processors: [memory_limiter, resource, batch, attributes/cluster]
{{- if .Values.openTelemetry.kafka.enabled }}
  exporters: [kafka/traces]
{{- else }}
  exporters: [failover/opensearch_traces]
traces/failover_a:
  receivers: [failover/opensearch_traces]
  processors: [attributes/failover_username_a]
  exporters: [opensearch/failover_a_traces]
traces/failover_b:
  receivers: [failover/opensearch_traces]
  processors: [attributes/failover_username_b]
  exporters: [opensearch/failover_b_traces]
{{- end }}
{{- end }}
