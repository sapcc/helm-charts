{{- define "auditpoller.receiver" }}
filelog/auditpoller:
  include_file_path: true
  include: [ /var/log/pods/audit-logs-otel_audit-poller*/audit-poller/*.log ]
  exclude: [ /var/log/pods/audit-logs-otel_audit-logs-collector* ]
  operators:
    - id: container-parser
      type: container
    - id: parser-containerd-auditpoller
      type: add
      field: resource["container.runtime"]
      value: "containerd"
{{ end }}

{{- define "auditpoller.processors" }}

transform/auditpoller:
  error_mode: ignore
  log_statements:
    - context: log
      statements:
        - set(log.time_unix_nano, log.observed_time_unix_nano)
        - merge_maps(log.attributes, ParseJSON(log.body), "upsert") where IsMatch(log.body, "^\\{")

attributes/auditpoller:
  actions:
    - action: insert
      key: log.type
      value: "auditpoller"
{{ end }}

{{- define "auditpoller.pipelines" }}
logs/auditpoller_logs:
  receivers: [filelog/auditpoller]
  processors: [transform/auditpoller,attributes/auditpoller,k8sattributes,attributes/cluster]
  exporters: [forward]
{{- end }}

