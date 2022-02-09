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

secAttNotifier:
  enabled: {{ .Values.secAttNotifier.enabled }}
  awsAccess: {{ .Values.secAttNotifier.awsAccess }}
  awsSecret: {{ .Values.secAttNotifier.awsSecret }}
  cronusEndpoint: {{ .Values.secAttNotifier.cronusEndpoint }}
  sourceEmail: {{ .Values.secAttNotifier.sourceEmail }}
  templateName: {{ .Values.secAttNotifier.templateName }}
  ReturnPath: {{ .Values.secAttNotifier.ReturnPath }}
  secAttNotificationThreshold: {{ .Values.secAttNotifier.secAttNotificationThreshold }}
  secAttNotificationHour: {{ .Values.secAttNotifier.secAttNotificationHour }}
  secAttNotificationDay: {{ .Values.secAttNotifier.secAttNotificationDay }}
{{- end }}
