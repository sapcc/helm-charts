{{- if .Values.nebula.enabled -}}
nebula:
  cacheSize: {{ .Values.nebula.cacheSize }}
  listenAddr:
    http: :{{ .Values.nebula.http }} # default :1080
  keystone:
{{- if .Values.config.keystone }}
{{- range $key, $value := .Values.config.keystone }}
  {{- if $value }}
    {{ $key }}: {{ $value }}
  {{- end }}
{{- end }}
{{- if .Values.global.cronus_service_password }}
    password: {{ .Values.global.cronus_service_password }}
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
    username: {{ .Values.config.jira.username }}
    password: {{ .Values.config.jira.password }}
    serviceDeskID: {{ .Values.config.jira.serviceDeskID }}
    requestTypeID: {{ .Values.config.jira.requestTypeID }}
    customFieldID: {{ .Values.config.jira.customFieldID }}
    ticketSummaryTemplate: |
{{ .Values.config.jira.ticketSummaryTemplate | indent 6 }}
    ticketDescriptionTemplate: |
{{ .Values.config.jira.ticketDescriptionTemplate | indent 6 }}
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
    useCaseDescription: {{ .Values.config.useCaseDescription }}
    websiteURL: {{ .Values.config.websiteURL }}
  accountStatusPollDelay: {{ .Values.config.accountStatusPollDelay }}
  accountStatusTimeout: {{ .Values.config.accountStatusTimeout }}
  debug: {{ .Values.nebula.debug }}
  policy:
    project_admin: project_id:%(project_id)s and role:email_admin
    nebula:admin: rule:project_admin
{{- end -}}
  metric:
    pushgatewayUrl: {{ .Values.config.pushgatewayUrl }}
    metricService: {{ .Values.config.nebula.metricService }}

