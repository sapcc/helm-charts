---
jobs:
- name: "default"
  interval: '1m'
  connections:
  - '{{ include "mysql_metrics.db_path_for_exporter" . }}'
  {{- if .Values.queryCell2 }}
  - '{{ include "cell2_db_path_for_exporter" . }}'
  {{- end }}
  {{- if .Values.customSources }}
  {{- range $customSource := .Values.customSources }}
  - {{ $customSource | quote }}
  {{- end }}
  {{- end }}
  queries:
{{ toYaml .Values.customMetrics | indent 4 }}
