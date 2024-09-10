---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule

metadata:
  name: octobus-query-exporter-alerts-audit
  labels:
    app: octobus-query-exporter
    tier: infra
    type: alerting-rules
    prometheus: infra-frontend
spec:
  groups:
    - name: audit
      rules:
        - alert: OctobusAuditLogsSourceMissing
          expr: rate(elasticsearch_octobus_audit_no_source_hits[60m]) > 0
          for: 5m
          labels:
            severity: warning
            service: "logs"
            support_group: "observability"
            meta: "Audit events have no source set"
            dashboard: audit-log-shipping
            playbook: 'docs/support/playbook/opensearch/octobus/audit-source-missing/#audit-source-for-event-missing'
          annotations:
            description: "Audit Logs should have field `sap.cc.audit.source`"
            summary: "Audit Logs indexed without source field"
        - alert: OctobusAuditLogsDeadletter
          expr: rate(elasticsearch_octobus_audit_deadletter_hits[60m]) > 0
          for: 5m
          labels:
            severity: warning
            service: "logs"
            support_group: "observability"
            meta: "Audit events send to deadletter index"
            dashboard: audit-log-shipping
            playbook: 'docs/support/playbook/opensearch/octobus/audit-source-missing/#audit-events-in-deadletter-index'
          annotations:
            description: "Audit Logs are not indexed correctly"
            summary: "Check `*deadletter*` index for the reason"
    {{- if .Values.octobus_query_exporter.auditSources }}
    {{- range .Values.octobus_query_exporter.auditSources }}
    {{- $name := .name }}
    {{- if contains "-" $name }}
    {{- $name = replace "-" "_" $name }}
    {{- end }}
    {{- $name = camelcase $name }}
        - alert: OctobusAuditLogs{{ $name }}Missing
          expr: sum by (source) (rate(elasticsearch_octobus_audit_source_doc_count{source="{{ .name }}"}[{{ .interval }}])) == 0
          for: 5m
          labels:
            severity: warning
            service: "logs"
            support_group: "observability"
            meta: "Audit events for {{ .name }} missing"
            dashboard: audit-log-shipping
            playbook: 'docs/support/playbook/opensearch/octobus/audit-source-missing/#audit-events-missing'
          annotations:
            description: "There have been no logs for {{ .name }} in the last {{ .interval }}"
            summary: "Audit logs missing for {{ .name }}"
    {{- end }}
    {{- end }}
    {{- if .Values.auditSourcesRegional }}
    {{- range .Values.auditSourcesRegional }}
    {{- $name := .name }}
    {{- if contains "-" $name }}
    {{- $name = replace "-" "_" $name }}
    {{- end }}
    {{- $name = camelcase $name }}
        - alert: OctobusAuditLogs{{ $name }}Missing
          expr: elasticsearch_octobus_audit_source_doc_count{source="{{ .name }}"} == 0
          for: {{ .interval }}
          labels:
            severity: warning
            service: "logs"
            support_group: "observability"
            meta: "Audit events for {{ .name }} missing"
            dashboard: audit-log-shipping
            playbook: 'docs/support/playbook/opensearch/octobus/audit-source-missing/#audit-events-missing'
          annotations:
            description: "There have been no logs for {{ .name }} in the last {{ .interval }}"
            summary: "Audit logs missing for {{ .name }}"
    {{- end }}
    {{- end }}
