f5:
  enabled: {{ .Values.f5.enabled }}
  devices: {{- .Values.f5.devices | toYaml | nindent 2 }}