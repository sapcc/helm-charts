{{/*
SPDX-FileCopyrightText: 2024 SAP SE or an SAP affiliate company and Greenhouse contributors
SPDX-License-Identifier: Apache-2.0
*/}}
{{- define "syslog.receiver" }}
syslog/tcp:
  operators:
  - field: attributes.log.type
    id: syslogtcp
    type: add
    value: syslogtcp
  protocol: rfc5424
  tcp:
    listen_address: 0.0.0.0:{{ .Values.openTelemetry.externalCollector.syslogConfig.tcp_port }}
    add_attributes: true
syslog/udp:
  location: UTC
  operators:
  - field: attributes.log.type
    id: syslogudp
    type: add
    value: syslogudp
  protocol: rfc3164
  udp:
    listen_address: 0.0.0.0:{{ .Values.openTelemetry.externalCollector.syslogConfig.udp_port }}
    add_attributes: true
    async: {}
{{- end }}

{{- define "syslog_tls.receiver" }}
syslog/tcp-tls:
  operators:
  - field: attributes.log.type
    id: syslogtcptls
    type: add
    value: syslogtcptls
  protocol: rfc5424
  tcp:
    listen_address: 0.0.0.0:{{ .Values.openTelemetry.externalCollector.syslogTLSConfig.tcp_port }}
    add_attributes: true
    tls:
      cert_file: /etc/ssl/syslog-tls/tls.crt
      key_file: /etc/ssl/syslog-tls/tls.key
      ca_file: /etc/ssl/syslog-tls/ca.crt
{{- end }}

{{- define "syslog.exporter" }}
{{- if not .Values.openTelemetry.kafka.enabled }}
opensearch/failover_a_syslog:
  http:
    auth:
      authenticator: basicauth/failover_a
    endpoint: {{ required "openTelemetry.openSearchLogs.endpoint is required when openTelemetry.kafka.enabled=false" $.Values.openTelemetry.openSearchLogs.endpoint }}
  logs_index: logs-datastream
  retry_on_failure:
    enabled: true
    initial_interval: 1s
    max_interval: 5s
    max_elapsed_time: 30s
  timeout: 10s
opensearch/failover_b_syslog:
  http:
    auth:
      authenticator: basicauth/failover_b
    endpoint: {{ required "openTelemetry.openSearchLogs.endpoint is required when openTelemetry.kafka.enabled=false" $.Values.openTelemetry.openSearchLogs.endpoint }}
  logs_index: logs-datastream
  retry_on_failure:
    enabled: true
    initial_interval: 1s
    max_interval: 5s
    max_elapsed_time: 30s
  timeout: 10s
{{- end }}
{{- end }}

{{- define "syslog.connectors" }}
{{- if not .Values.openTelemetry.kafka.enabled }}
failover/opensearch_syslog:
  priority_levels:
    - [logs/failover_a_syslog]
    - [logs/failover_b_syslog]
  retry_interval: 1h
  sending_queue:
    block_on_overflow: true
    enabled: true
    num_consumers: 2
    queue_size: 10000
    sizer: requests
{{- end }}
{{- end }}

{{- define "syslog.pipeline" }}
{{- if not .Values.openTelemetry.kafka.enabled }}
logs/failover_a_syslog:
  receivers: [failover/opensearch_syslog]
  processors: [attributes/failover_username_a]
  exporters: [opensearch/failover_a_syslog]

logs/failover_b_syslog:
  receivers: [failover/opensearch_syslog]
  processors: [attributes/failover_username_b]
  exporters: [opensearch/failover_b_syslog]

{{- end }}
logs/syslog_tcp:
  receivers: [syslog/tcp]
  processors: [attributes/cluster, batch]
{{- if .Values.openTelemetry.kafka.enabled }}
  exporters: [kafka]
{{- else }}
  exporters: [failover/opensearch_syslog]
{{- end }}

logs/syslog_udp:
  receivers: [syslog/udp]
  processors: [attributes/cluster, batch]
{{- if .Values.openTelemetry.kafka.enabled }}
  exporters: [kafka]
{{- else }}
  exporters: [failover/opensearch_syslog]
{{- end }}
{{- end }}

{{- define "syslog_tls.pipeline" }}
logs/syslog_tcp_tls:
  receivers: [syslog/tcp-tls]
  processors: [attributes/cluster, batch]
{{- if .Values.openTelemetry.kafka.enabled }}
  exporters: [kafka]
{{- else }}
  exporters: [failover/opensearch_syslog]
{{- end }}
{{- end }}
