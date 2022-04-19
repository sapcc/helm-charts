{{- if .Values.updater.enabled -}}
updaterConfig:
  prometheus: {{ .Values.updater.prometheus }}
  mcUrl: {{ .Values.config.multiCloud.endpoint }}
  mcUser: {{ .Values.config.multiCloud.username }}
  mcPassword: {{ .Values.config.multiCloud.password }}
  awsRegion: {{ .Values.config.allowedServices.email }}
  awsAccess: {{ .Values.config.awsAccess }}
  awsSecret: {{ .Values.config.awsSecret }}
  region: {{ .Values.config.keystone.region }}
  sleepDuration: {{ .Values.updater.sleepDuration }}
  notification:
    enabled: {{ .Values.secAttNotifier.enabled }}
    awsAccess: {{ .Values.secAttNotifier.awsAccess }}
    awsSecret: {{ .Values.secAttNotifier.awsSecret }}
    endpoint: {{ .Values.secAttNotifier.cronusEndpoint }}
    hour: {{ .Values.secAttNotifier.secAttNotificationHour }}
    day: {{ .Values.secAttNotifier.secAttNotificationDay }}
    sender: {{ .Values.secAttNotifier.sourceEmail }}
    {{- range $key, $value := .Values.updater.contacts }}
    contact:
      - {{ $value }}
    {{- end }}
{{- end }}
