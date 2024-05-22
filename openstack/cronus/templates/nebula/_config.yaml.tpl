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
  intSMTP:
    endpoint: {{ .Values.config.intSMTP.endpoint }}
    username: {{ .Values.config.intSMTP.username }}
    owners:
{{- range $v := .Values.config.intSMTP.owners }}
      - {{ $v }}
{{- end }}
  group: {{ .Values.config.group }}
  technicalResponsible: {{ .Values.config.technicalResponsible }}
  aws:
    region: {{ .Values.config.allowedServices.email }}
    accessKeyRotationDays: {{ .Values.global.accessKeyRotationDays }}
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
    useCaseDescription: |
{{ .Values.config.useCaseDescription | indent 6 }}
    websiteURL: {{ .Values.config.websiteURL }}
{{- if .Values.config.sesAdditionalContactEmails }}
    sesAdditionalContactEmails:
{{- range $key, $value := .Values.config.sesAdditionalContactEmails }}
    - {{ $value }}
{{- end }}
{{- end }}
{{- $ac := .Values.config.alternateContact | default .Values.global.alternateContact }}
{{- if $ac }}
    alternateContact:
      emailAddress: {{ $ac.emailAddress }}
      name: {{ $ac.name }}
      title: {{ $ac.title }}
      phoneNumber: {{ $ac.phoneNumber }}
{{- end }}
  accountStatusPollDelay: {{ .Values.config.accountStatusPollDelay }}
  accountStatusTimeout: {{ .Values.config.accountStatusTimeout }}s
  debug: {{ .Values.nebula.debug }}
  policy:
{{- range $key, $value := .Values.config.nebulaPolicy }}
    {{ $key }}: {{ $value }}
{{- end }}
{{- if .Values.hermes }}
  auditSink:
    queueName: {{ .Values.config.nebulaAuditSink.queueName }}
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
{{- if .Values.nebula.secAttrsUpdateAfter }}
  secAttrsUpdateAfter: {{ .Values.nebula.secAttrsUpdateAfter }}
{{- end }}
{{- if .Values.nebula.leasedUntilUpdateBefore }}
  leasedUntilUpdateBefore: {{ .Values.nebula.leasedUntilUpdateBefore }}
{{- end }}
{{- if .Values.notifier.enabled }}
  notifier:
    host: {{ .Values.notifier.host }}
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
    authEndpoint: {{ .Values.pki.authEndpoint }}
    enrollEndpoint: {{ .Values.pki.enrollEndpoint }}
    subjectPattern: {{ .Values.pki.subjectPattern }}
    validityDays: {{ .Values.pki.validityDays }}
{{- end }}
{{- if .Values.postfix.postfixEnabled }}
  postfixEnabled: {{ .Values.postfix.postfixEnabled }}
  postfixDNS:
    zoneID: {{ .Values.postfixDNS.zoneID }}
    auth:
      auth_url: {{ .Values.postfixDNS.auth.auth_url }}
  ldap:
    url: "{{ tpl .Values.postfix.ldap.url $ }}"
    {{- if .Values.postfix.ldap.clientKeyPath }}
    clientCertPath: {{ .Values.postfix.ldap.clientCertPath }}
    clientKeyPath: {{ .Values.postfix.ldap.clientKeyPath }}
    {{- else }}
    certPem: |
{{ .Values.postfix.ldap.certPem | indent 6 }}
    certKey: |
{{ .Values.postfix.ldap.certKey | indent 6 }}
    {{- end }}
    baseDN: {{ .Values.postfix.ldap.baseDN }}
    projectAttributes:
{{- range $key, $value := .Values.postfix.ldap.projectAttributes }}
  {{- if $value }}
      - {{ $value }}
  {{- end }}
{{- end }}
{{- end }}
{{- if .Values.nebula.cors }}
  cors:
    enabled: {{ .Values.nebula.cors.enabled }}
    allowedOrigins:
{{- .Values.nebula.cors.allowedOrigins | toYaml | nindent 6 }}
    allowedHeaders:
{{- .Values.nebula.cors.allowedHeaders | toYaml | nindent 6 }}
{{- end }}
{{- end -}}
