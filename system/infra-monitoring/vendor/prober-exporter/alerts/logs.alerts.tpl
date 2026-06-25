groups:
  - name: OpenSearchLogsProbes
    rules:
      - alert: OpenSearchLogsDashboardDown
        expr: 'probe_success{instance=~"https://logs.+"} == 0'
        for: 15m
        labels:
          severity: warning
          tier: os
          service: logs
          support_group: observability
          meta: "OpenSearch logs dashboard down"
          dashboard: opensearch-logshipping
          persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/opensearch-overview?var-cluster=opensearch-logs"
          playbook: 'docs/support/playbook/opensearch/generic'
        annotations:
          description: "OpenSearchLogs dashboard is down"
          summary: "OpenSearchLogs dashboard is down"
      - alert: OpenSearchLogsClientEndpointDown
        expr: 'probe_success{instance=~"https://opensearch-logs-client.+"} == 0'
        for: 15m
        labels:
          severity: warning
          tier: os
          service: logs
          support_group: observability
          meta: "OpenSearch-Logs client nodes down"
          dashboard: opensearch-logshipping
          persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/opensearch-overview?var-cluster=opensearch-logs"
          playbook: 'docs/support/playbook/opensearch/generic'
        annotations:
          description: "OpenSearch Logs client nodes are down"
          summary: "OpenSearch Logs client nodes are down"