{{- if .Values.updater.enabled -}}
updaterConfig:
  prometheus: {{ .Values.updater.prometheus }}
  mcUrl: {{ .Values.config.multiCloud.endpoint }}
  mcUser: {{ .Values.config.multiCloud.username }}
  awsRegion: {{ .Values.config.allowedServices.email }}
  awsAccess: {{ .Values.config.awsAccess }}
  region: {{ .Values.config.keystone.region }}
  sleepDuration: {{ .Values.updater.sleepDuration }}
  applicationCredentialsProject: {{ .Values.updater.applicationCredentialsProject }}
  applicationCredentialsDomain: {{ .Values.updater.applicationCredentialsDomain }}
  applicationCredentialsName: {{ .Values.updater.applicationCredentialsName }}
  useCaseDescription: |
{{ .Values.config.useCaseDescription | indent 6 }}
  websiteURL: {{ .Values.config.websiteURL }}
  notification:
    enabled: {{ .Values.secAttNotifier.enabled }}
    ec2Access: {{ .Values.secAttNotifier.ec2Access }}
    smtpHost: {{ .Values.secAttNotifier.smtpHost }}
    port: {{ .Values.secAttNotifier.port }}
  {{- if .Values.secAttNotifier.days }}
    days:
    {{- range $key, $value := .Values.secAttNotifier.days }}
      - {{ $value }}
    {{- end }}
  {{- end }}
    endpoint: {{ .Values.secAttNotifier.cronusEndpoint }}
    leasedUntilLteMonths: {{ .Values.secAttNotifier.leasedUntilLteMonths }}
    hour: {{ .Values.secAttNotifier.secAttNotificationHour }}
    day: {{ .Values.secAttNotifier.secAttNotificationDay }}
    secondDay: {{ .Values.secAttNotifier.secondDay }}
    sender: {{ .Values.secAttNotifier.sourceEmail }}
  {{- if .Values.secAttNotifier.contacts }}
    contacts:
    {{- range $key, $value := .Values.secAttNotifier.contacts }}
      - {{ $value }}
    {{- end }}
  {{- end }}
    body: |
{{ .Values.secAttNotifier.body | indent 8 }}
    subject: {{ .Values.secAttNotifier.subject | quote }}
    charSet: {{ .Values.secAttNotifier.charSet }}
{{- end }}
