---
jobs:
- name: "default"
  interval: '1m'
  connections:
  {{- if and (hasKey .Values "connections") .Values.connections }}
    {{- range $name, $connection := .Values.connections }}
  - '{{ include "mysql_metrics.db_path_for_exporter_from_connections" (tuple $ $name $connection) }}'
    {{- end }}
  {{- else }}
  - '{{ include "mysql_metrics.db_path_for_exporter" . }}'
  {{- end }}
  queries:
{{ toYaml .Values.customMetrics | indent 4 }}
