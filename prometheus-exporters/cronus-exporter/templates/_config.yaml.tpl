{{- if .Values.exporter.enabled -}}
exporter:
  duration: {{ .Values.exporter.duration }}
  prometheusPort: {{ .Values.exporter.prometheusPort }}
  period: {{ .Values.exporter.period }}
  multicloudEndpoint: {{ .Values.config.multiCloud.endpoint }}
  multicloudUsername: {{ .Values.config.multiCloud.username }}
  multicloudPassword: {{ .Values.config.multiCloud.password }}
  awsRegion: {{ .Values.config.allowedServices.email }}
  awsAccess: {{ .Values.config.awsAccess }}
  awsSecret: {{ .Values.config.awsSecret }}
  keystoneRegion: {{ .Values.config.keystone.region }}
  receivingDelayMinute: {{ .Values.exporter.receivingDelayMinute }}
  sendingDelayMinute: {{ .Values.exporter.sendingDelayMinute }}
  getAccountsDelayHour: {{ .Values.exporter.getAccountsDelayHour }}
{{- end }}
