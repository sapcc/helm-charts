{{- if .Values.nebula.enabled -}}
nebula:
  cacheSize: {{ .Values.nebula.cacheSize }}
{{- if .Values.config.retry }}
  retry:
{{- if .Values.config.retry.maxConnectionRetries }}
    maxConnectionRetries: {{ .Values.config.retry.maxConnectionRetries }}
{{- end }}
{{- if .Values.config.retry.retryInterval }}
    retryInterval: {{ .Values.config.retry.retryInterval }}
{{- end }}
{{- end }}
  listenAddr:
    http: :{{ .Values.nebula.http }} # default :1080
    shutdownTimeout: {{ .Values.config.accountStatusTimeout }}s
    readTimeout: {{ .Values.nebula.readTimeout | default 30 }}s
    writeTimeout: {{ .Values.nebula.writeTimeout | default 30 }}s
    keepAliveTimeout: {{ .Values.nebula.keepAliveTimeout | default 60 }}s
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
  intSMTP:
    endpoint: {{ .Values.config.intSMTP.endpoint }}
    username: {{ .Values.config.intSMTP.username }}
    password: {{ .Values.config.intSMTP.password }}
    owners:
{{- range $v := .Values.config.intSMTP.owners }}
      - {{ $v }}
{{- end }}
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
    roleName: {{ .Values.config.roleName }}
    iamRolePolicyName: {{ .Values.config.iamRolePolicyName }}
    iamRolePolicy: |
{{ .Values.config.iamRolePolicy | indent 6 }}
    iamRoleTrustPolicy: |
{{ .Values.config.iamRoleTrustPolicy | indent 6 }}
    iamPolicy: |
{{ .Values.config.iamPolicy | indent 6 }}
    verifyEmailDomain: {{ .Values.config.verifyEmailDomain }}
    verifyEmailSecret: {{ .Values.config.verifyEmailSecret }}
    useCaseDescription: |
{{ .Values.config.useCaseDescription | indent 6 }}
    websiteURL: {{ .Values.config.websiteURL }}
{{- if .Values.config.sesAdditionalContactEmails }}
    sesAdditionalContactEmails:
{{- range $key, $value := .Values.config.sesAdditionalContactEmails }}
    - {{ $value }}
{{- end }}
{{- end }}
  accountStatusPollDelay: {{ .Values.config.accountStatusPollDelay }}
  accountStatusTimeout: {{ .Values.config.accountStatusTimeout }}s
  debug: {{ .Values.nebula.debug }}
  policy:
{{- range $key, $value := .Values.config.nebulaPolicy }}
    {{ $key }}: {{ $value }}
{{- end }}
{{- if .Values.hermes }}
{{- $user := .Values.rabbitmq_notifications.users.default.user }}
{{- $creds := .Values.hermes.rabbitmq.targets.cronus }}
  auditSink:
    rabbitmqUrl: amqp://{{ $user }}:{{ $creds.password }}@{{ if .Values.config.nebulaAuditSink.host }}{{ .Values.config.nebulaAuditSink.host }}{{ else }}{{ $creds.host }}.{{ .Values.global.region }}.{{ .Values.global.tld }}:5672{{ end }}
    queueName: {{ $creds.queue_name }}
    internalQueueSize: {{ .Values.config.nebulaAuditSink.internalQueueSize }}
    maxContentLen: {{ .Values.config.nebulaAuditSink.maxContentLen | int64 }}
{{- if .Values.config.nebulaAuditSink.contentTypePrefixes }}
    contentTypePrefixes:
{{- range $k, $v := .Values.config.nebulaAuditSink.contentTypePrefixes }}
      - {{ $v }}
{{- end }}
{{- end }}
{{- if .Values.config.nebulaAuditSink.queryKeysToMask }}
    queryKeysToMask:
{{- range $svc, $list := .Values.config.nebulaAuditSink.queryKeysToMask }}
      {{ $svc }}:
{{- range $k, $v := $list }}
      - {{ $v }}
{{- end }}
{{- end }}
{{- end }}
{{- if .Values.config.nebulaAuditSink.jsonKeysToMask }}
    jsonKeysToMask:
{{- range $svc, $list := .Values.config.nebulaAuditSink.jsonKeysToMask }}
      {{ $svc }}:
{{- range $k, $v := $list }}
      - {{ $v }}
{{- end }}
{{- end }}
{{- end }}
    debug: {{ .Values.config.nebulaAuditSink.debug | default false }}
{{- end }}
{{- if .Values.nebula.sentryDsn }}
  sentryDsn: {{ .Values.nebula.sentryDsn }}
{{- end }}
{{- if .Values.nebula.secAttrsUpdateAfter }}
  secAttrsUpdateAfter: {{ .Values.nebula.secAttrsUpdateAfter }}
{{- end }}
{{- if .Values.nebula.leasedUntilUpdateBefore }}
  leasedUntilUpdateBefore: {{ .Values.nebula.leasedUntilUpdateBefore }}
{{- end }}
{{- if .Values.notifier.enabled }}
  notifier:
    host: {{ .Values.notifier.host }}
    smtpUsername: {{ .Values.notifier.smtpUsername }}
    smtpPassword: {{ .Values.notifier.smtpPassword }}
    sender: {{ .Values.notifier.sender }}
    recipients:
  {{- range $key, $value := .Values.config.sesAdditionalContactEmails }}
      - {{ $value }}
  {{- end }}
    activationTitle: {{ .Values.notifier.activationTitle }}
    activationBody: |
{{ .Values.notifier.activationBody | indent 6 }}
    deletionTitle: {{ .Values.notifier.deletionTitle }}
    deletionBody: |
{{ .Values.notifier.deletionBody | indent 6 }}
{{- end }}
{{- if .Values.pki.enabled }}
  pki:
    clientID: {{ .Values.pki.clientID }}
    accountID: {{ .Values.pki.accountID }}
    clientSecret: {{ .Values.pki.clientSecret }}
    authEndpoint: {{ .Values.pki.authEndpoint }}
    enrollEndpoint: {{ .Values.pki.enrollEndpoint }}
    subjectPattern: {{ .Values.pki.subjectPattern }}
    validityDays: {{ .Values.pki.validityDays }}
{{- end }}
{{- end -}}
