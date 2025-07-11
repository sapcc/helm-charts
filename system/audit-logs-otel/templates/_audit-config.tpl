{{- define "audit.processors" }}
attributes/audit_logs:
  actions:
    - action: insert
      key: audit.timestamp"
      value: "audit"
    - action: insert
      key: audit.action.operation"
      value: "audit"
    - action: insert
      key: audit.initiator.name"
      value: "audit"
    - action: insert
      key: audit.resource.name"
      value: "audit"
    - action: insert
      key: audit.action.resource.type"
      value: "audit"
    - action: insert
      key: audit.result"
      value: "audit"
    - action: insert
      key: audit.logsource"
      value: "audit"
{{ end }}
{{- define "audit.pipeline" }}
logs/audit_journald:
  receivers: [filelog/journald]
  processors: [k8sattributes,attributes/cluster]
  exporters: [forward]
logs/audit_containerd:
  receivers: [filelog/containerd]
  processors: [k8sattributes,attributes/cluster]
  exporters: [forward]
logs/audit_filelog:
  receivers: [filelog/audit_logs]
  processors: [k8sattributes,attributes/cluster]
  exporters: [forward]
{{- end }}
