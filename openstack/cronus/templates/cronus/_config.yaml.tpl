{{- if .Values.cronus.enabled -}}
cronus:
  cacheSize: {{ .Values.cronus.cacheSize }}
  billingCacheTTL: {{ .Values.config.billingCacheTTL }}
  barbicanCacheTTL: {{ .Values.config.barbicanCacheTTL }}
{{- if .Values.config.retry }}
  retry:
{{- if .Values.config.retry.maxConnectionRetries }}
    maxConnectionRetries: {{ .Values.config.retry.maxConnectionRetries }}
{{- end }}
{{- if .Values.config.retry.retryInterval }}
    retryInterval: {{ .Values.config.retry.retryInterval }}
{{- end }}
{{- end }}
  aws:
    forwardUserAgent: {{ .Values.config.forwardUserAgent }}
    allowedServices:
    {{- range $key, $value := .Values.config.allowedServices }}
      {{ $key }}: {{ $value }}
    {{- end }}
  listenAddr:
    http: :{{ .Values.cronus.http }} # default :5000
    smtp: :{{ .Values.cronus.smtp }} # default :1025
{{- if .Values.cronus.listenProxyProtocol }}
    proxyProtocol: {{ .Values.cronus.listenProxyProtocol }}
{{- end }}
    shutdownTimeout: {{ .Values.cronus.terminationGracePeriod | default 60 }}s
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
{{- if .Values.config.smtpBackends }}
  # extra SMTP backends and a list of recipient domains
  smtpBackends:
{{- range $k, $v := .Values.config.smtpBackends }}
    {{ $k }}:
      host: {{ $v.host }}
{{- if $v.domains }}
      domains:
{{- range $kd, $vd := $v.domains }}
        - {{ $vd }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
  # blocked sender domains
  blockedDomains:
{{- range $k, $v := .Values.config.blockedDomains }}
    - {{ $v }}
{{- end }}
    - {{ .Values.config.verifyEmailDomain }}
  debug: {{ .Values.cronus.debug }}
  policy:
{{- range $key, $value := .Values.config.cronusPolicy }}
    {{ $key }}: {{ $value }}
{{- end }}
{{- if .Values.hermes }}
{{- $user := .Values.rabbitmq_notifications.users.default.user }}
{{- $creds := .Values.hermes.rabbitmq.targets.cronus }}
  auditSink:
    rabbitmqUrl: amqp://{{ $user }}:{{ $creds.password }}@{{ if .Values.config.cronusAuditSink.host }}{{ .Values.config.cronusAuditSink.host }}{{ else }}{{ $creds.host }}.{{ .Values.global.region }}.{{ .Values.global.tld }}:5672{{ end }}
    queueName: {{ $creds.queue_name }}
    internalQueueSize: {{ .Values.config.cronusAuditSink.internalQueueSize }}
    maxContentLen: {{ .Values.config.cronusAuditSink.maxContentLen | int64 }}
{{- if .Values.config.cronusAuditSink.contentTypePrefixes }}
    contentTypePrefixes:
{{- range $k, $v := .Values.config.cronusAuditSink.contentTypePrefixes }}
      - {{ $v }}
{{- end }}
{{- end }}
{{- if .Values.config.cronusAuditSink.queryKeysToMask }}
    queryKeysToMask:
{{- range $svc, $list := .Values.config.cronusAuditSink.queryKeysToMask }}
      {{ $svc }}:
{{- range $k, $v := $list }}
      - {{ $v }}
{{- end }}
{{- end }}
{{- end }}
{{- if .Values.config.cronusAuditSink.jsonKeysToMask }}
    jsonKeysToMask:
{{- range $svc, $list := .Values.config.cronusAuditSink.jsonKeysToMask }}
      {{ $svc }}:
{{- range $k, $v := $list }}
      - {{ $v }}
{{- end }}
{{- end }}
{{- end }}
    debug: {{ .Values.config.cronusAuditSink.debug | default false }}
{{- end }}
{{- if .Values.cronus.sentryDsn }}
  sentryDsn: {{ .Values.cronus.sentryDsn }}
{{- end }}
{{- end -}}
