f5:
  enabled: {{ .Values.f5.enabled }}
  devices: {{- .Values.f5.devices | toYaml | nindent 2 }}
  domain_suffix: {{ .Values.f5.domain_suffix }}