{{- if .Values.nebula.enabled -}}
nebula:
  cacheSize: {{ .Values.nebula.cacheSize }}
  listenAddr:
    http: :{{ .Values.nebula.port.http }} # default :1080
  keystone:
{{- if .Values.config.keystone }}
{{- range $key, $value := .Values.config.keystone }}
  {{- if $value }}
    {{ $key }}: {{ $value }}
  {{- end }}
{{- end }}
{{ else }}
    authUrl: {{ .Values.config.authUrl }}
    applicationCredentialID: {{ .Values.config.applicationCredentialID }}
    applicationCredentialSecret: {{ .Values.config.applicationCredentialSecret }}
    region: {{ .Values.config.region }}
    endpointType: {{ .Values.config.endpointType }}
{{- end }}

  serviceUser:
    username: {{ .Values.config.serviceUsername }}
    password: {{ .Values.config.servicePassword }}
  jira:
    username: {{ .Values.config.jiraUsername }}
    password: {{ .Values.config.jiraPassword }}
  group: {{ .Values.config.group }}
  technicalResponsible: {{ .Values.config.technicalResponsible }}
  aws:
    region: {{ .Values.config.allowedServices.email }}
    access: {{ .Values.config.awsAccess }}
    secret: {{ .Values.config.awsSecret }}
    technicalUsername: {{ .Values.config.technicalUsername }}
    policyName: {{ .Values.config.awsPolicy }}
    verifyEmailDomain: {{ .Values.config.verifyEmailDomain }}
    verifyEmailSecret: {{ .Values.config.verifyEmailSecret }}
  accountStatusPollDelay: {{ .Values.config.accountStatusPollDelay }}
  accountStatusTimeout: {{ .Values.config.accountStatusTimeout }}
  debug: {{ .Values.nebula.debug }}
{{- end -}}
