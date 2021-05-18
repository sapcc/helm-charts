{{- if .Values.updater.enabled -}}
exporter:
  updaterLoopInterval: {{ .Values.exporter.updaterLoopInterval }}
  pushgatewayUrl: {{ .Values.exporter.pushgatewayUrl }}
multicloudEndpoint: {{ .Values.config.multiCloud.endpoint }}
multicloudUsername: {{ .Values.config.multiCloud.username }}
multicloudPassword: {{ .Values.config.multiCloud.password }}
awsRegion: {{ .Values.config.allowedServices.email }}
awsAccess: {{ .Values.config.awsAccess }}
awsSecret: {{ .Values.config.awsSecret }}
keystoneRegion: {{ .Values.config.keystone.region }}
{{- end }}