# global configuration
global:
  resolve_timeout: 16m

route:
  group_by:
    {{- toYaml .Values.groupBy | nindent 4 }}
  group_wait: {{ .Values.groupWait }}
  group_interval: {{ .Values.groupInterval }}
  repeat_interval: {{ .Values.repeatInterval }}
  receiver: dev/null

receivers:
  - name: dev/null

templates:
  - /notification-templates/*.tmpl
