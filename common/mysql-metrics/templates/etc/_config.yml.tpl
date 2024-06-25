---
jobs:
- name: "default"
  interval: '1m'
  connections:
  - "mysql://{{ required ".Values.db_user missing" .Values.db_user }}:{{if hasKey .Values "db_password"}}{{ .Values.db_password }}{{ else }}{{include "mysql_metrics.db_password" .}}{{- end -}}@tcp({{ include "metrics_db_host" . }}:3306)/{{ required ".Values.db_name missing" .Values.db_name }}"
  {{- if .Values.queryCell2 }}
  - "{{ include "cell2_db_path_for_exporter" . }}"
  {{- end }}
  {{- if .Values.customSources }}
  {{- range $customSource := .Values.customSources }}
  - {{ $customSource | quote }}
  {{- end }}
  {{- end }}
  queries:
{{ toYaml .Values.customMetrics | indent 4 }}
