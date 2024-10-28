{{- if .Values.exporter.enabled -}}
exporter:
  duration: {{ .Values.exporter.duration }}
  nebulaEndpoint: {{ .Values.simulator.nebulaApiEndpoint }}
  prometheusPort: {{ .Values.exporter.prometheusPort }}
  period: {{ .Values.exporter.period }}
  multicloudEndpoint: {{ .Values.config.multiCloud.endpoint }}
  multicloudUsername: {{ .Values.config.multiCloud.username }}
  awsRegion: {{ .Values.config.allowedServices.email }}
  keystoneRegion: {{ .Values.config.keystone.region }}
  receivingDelay: {{ .Values.exporter.receivingDelay }}
  sendingDelay: {{ .Values.exporter.sendingDelay }}
  suppressionDelay: {{ .Values.exporter.suppressionDelay }}
  accountsDelay: {{ .Values.exporter.accountsDelay }}
  identityDelay: {{ .Values.exporter.identityDelay }}
  quotaDelay: {{ .Values.exporter.quotaDelay }}
  clientErrorDelay: {{ .Values.exporter.clientErrorDelay }}
  maxAllowedSuppression: {{ .Values.exporter.maxAllowedSuppression }}
  getAccountsDelayHour: {{ .Values.exporter.getAccountsDelayHour }}
{{- end }}