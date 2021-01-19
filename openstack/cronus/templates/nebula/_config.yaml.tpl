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
  multiCloud:
    endpoint: {{ .Values.config.multiCloud.endpoint }}
    username: {{ .Values.config.multiCloud.username }}
    password: {{ .Values.config.multiCloud.password }}
  # TODO: needs to be deleted in newer versions
  serviceUser:
    username: {{ .Values.config.serviceUsername }}
    password: {{ .Values.config.serviceUsername }}
  jira:
    endpoint: {{ .Values.config.jira.endpoint }}
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
    policyName: {{ .Values.config.policyName }}
    iamPolicy: |
{{ .Values.config.iamPolicy | indent 6 }}
    verifyEmailDomain: {{ .Values.config.verifyEmailDomain }}
    verifyEmailSecret: {{ .Values.config.verifyEmailSecret }}
    useCaseDescription: {{ .Values.config.useCaseDescription }}
    websiteURL: {{ .Values.config.websiteURL }}
  accountStatusPollDelay: {{ .Values.config.accountStatusPollDelay }}
  accountStatusTimeout: {{ .Values.config.accountStatusTimeout }}
  debug: {{ .Values.nebula.debug }}
  policy:
{{- range $key, $value := .Values.config.nebulaPolicy }}
    {{ $key }}: {{ $value }}
{{- end }}
{{- if .Values.hermes }}
{{- $user := .Values.rabbitmq_notifications.users.default.user }}
{{- $creds := .Values.hermes.rabbitmq.targets.cronus }}
  auditSink:
    rabbitmqUrl: amqp://{{ $user }}:{{ $creds.password }}@{{ if .Values.config.nebulaAuditSink.host }}{{ .Values.config.nebulaAuditSink.host }}{{ else }}{{ $creds.host }}.{{ .Values.global.region }}.cloud.sap:5672{{ end }}
    queueName: {{ $creds.queue_name }}
    internalQueueSize: {{ .Values.config.nebulaAuditSink.internalQueueSize }}
    maxContentLen: {{ .Values.config.nebulaAuditSink.maxContentLen | int64 }}
{{- if .Values.config.nebulaAuditSink.contentTypePrefixes }}
    contentTypePrefixes:
{{- range $k, $v := .Values.config.nebulaAuditSink.contentTypePrefixes }}
      - {{ $v }}
{{- end }}
{{- end }}
    debug: {{ .Values.config.nebulaAuditSink.debug | default false }}
{{- end }}
{{- end -}}
