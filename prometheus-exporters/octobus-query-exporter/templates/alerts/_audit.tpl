---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule

metadata:
  name: elastic-query-exporter-audit
  labels:
    app: elastic-query-exporter
    tier: infra
    type: alerting-rules
    prometheus: {{ required ".Values.alerts.prometheus missing" .Values.alerts.prometheus | quote }}

spec:
  groups:
    - name: audit
      rules:
        - alert: OctobusAuditLogsSourceMissing
          expr: elasticsearch_octobus_audit_no_source_hits > 0
          for: 5m
          labels:
            severity: info
            tier: monitor
            service: audit
            meta: "Audit events has no source set"
            dashboard: audit-log-shipping
          annotations:
            description: "Audit Logs should have field `sap.cc.audit.source`"
            summary: "Audit Logs indexed without source field"
        - alert: OctobusAuditLogsDeadletter
          expr: elasticsearch_octobus_audit_deadletter_hits > 0
          for: 5m
          labels:
            severity: info
            tier: monitor
            service: audit
            meta: "Audit events send to deadletter index"
            dashboard: audit-log-shipping
          annotations:
            description: "Audit Logs are not indexed correctly"
            summary: "Audit Logs indexing not working"
    {{- range .Values.auditSources }}
    {{- $name := .name }}
    {{- if contains "-" $name }}
    {{- $name = replace "-" "_" $name }}
    {{- end }}
    {{- $name = camelcase $name }}
        - alert: OctobusAuditLogs{{ $name }}Missing
          expr: elasticsearch_octobus_audit_source_doc_count{source="{{ .name }}"} == 0
          for: {{ .interval }}
          labels:
            severity: info
            tier: monitor
            service: audit
            meta: "Audit events for {{ .name }} missing"
            dashboard: audit-log-shipping
          annotations:
            description: "There have been no logs for {{ .name }} in the last {{ .interval }}"
            summary: "Audit logs missing for {{ .name }}"
    {{- end }}
