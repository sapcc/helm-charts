{{- if .Values.cronus.enabled -}}
cronus:
  hostname: cronus.{{ .Values.global.region }}.{{ .Values.global.tld }}
  cacheSize: {{ .Values.cronus.cacheSize }}
  billingCacheTTL: {{ .Values.config.billingCacheTTL }}
  barbicanCacheTTL: {{ .Values.config.barbicanCacheTTL }}
  awsSignV2TTL: {{ .Values.config.awsSignV2TTL }}
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
    replaceServices:
    {{- range $key, $value := .Values.config.replaceServices }}
      {{ $key | quote }}: {{ $value }}
    {{- end }}
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
{{- if .Values.cronus.proxyHeaderTimeout }}
    proxyHeaderTimeout: {{ .Values.cronus.proxyHeaderTimeout }}
{{- end }}
    shutdownTimeout: {{ .Values.cronus.terminationGracePeriod | default 60 }}s
    readTimeout: {{ .Values.cronus.readTimeout | default 30 }}s
    writeTimeout: {{ .Values.cronus.writeTimeout | default 30 }}s
    keepAliveTimeout: {{ .Values.cronus.keepAliveTimeout | default 60 }}s
{{- if .Values.cronus.tls }}
{{- if .Values.cronus.smtps }}
    startTls: :{{ .Values.cronus.smtps }} # default :587
{{- end }}
    tls:
      namespace: {{ .Values.cronus.tls.namespace | default "cronus" }}
      serverTlsName: {{ .Values.cronus.tls.serverTlsName }}
{{- if or .Values.cronus.tls.clientCA .Values.global.clientCA .Values.cronus.tls.clientTlsAuth .Values.global.clientTlsAuth }}
      clientTlsAuth: {{ .Values.cronus.tls.clientTlsAuth | default .Values.global.clientTlsAuth }}
{{- if or .Values.cronus.tls.clientCertOU .Values.global.clientCertOU }}
      clientCertOU: {{ .Values.cronus.tls.clientCertOU | default .Values.global.clientCertOU }}
{{- end }}
      clientCA: |
{{ .Values.cronus.tls.clientCA | default .Values.global.clientCA | indent 8 }}
{{- end }}
      errInterval: {{ .Values.cronus.tls.errInterval | default 60 }}
{{- end }}
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
{{- else }}
    authUrl: {{ .Values.config.authUrl }}
    applicationCredentialID: {{ .Values.config.applicationCredentialID }}
    applicationCredentialSecret: {{ .Values.config.applicationCredentialSecret }}
    region: {{ .Values.config.region }}
    endpointType: {{ .Values.config.endpointType }}
{{- end }}
{{- if .Values.config.workQueue }}
{{- $r_user := .Values.rabbitmq.users.default.user }}
{{- $r_creds := .Values.rabbitmq.users.default.password }}
  workQueue:
    enabled: {{ .Values.config.workQueue.enabled }}
    rabbitmqUri: amqp://{{ $r_user }}:{{ $r_creds }}@cronus-rabbitmq:5672/
{{- if .Values.config.workQueue.queueName }}
    queueName: {{ .Values.config.workQueue.queueName }}
{{- end }}
{{- if .Values.config.workQueue.exchangeName }}
    exchangeName: {{ .Values.config.workQueue.exchangeName }}
{{- end }}
{{- if .Values.config.workQueue.workerPrefetchCount }}
    workerPrefetchCount: {{ .Values.config.workQueue.workerPrefetchCount }}
{{- end }}
{{- if .Values.config.workQueue.workerPrefetchSize }}
    workerPrefetchSize: {{ .Values.config.workQueue.workerPrefetchSize }}
{{- end }}
    trailLimit: {{ .Values.config.workQueue.trailLimit }}
    trailTimeBaseFactor: {{ .Values.config.workQueue.trailTimeBaseFactor }}
    trailTimeRandMaxNumber: {{ .Values.config.workQueue.trailTimeRandMaxNumber }}
    maxContainerNum: {{ .Values.config.workQueue.maxContainerNum }}
    reconnectWatcherLimit: {{ .Values.config.workQueue.reconnectWatcherLimit }}
    jobQueue:
      deadLetterEnabled: {{ .Values.config.workQueue.jobQueue.deadLetterEnabled }}
      queueName: {{ .Values.config.workQueue.jobQueue.queueName }}
      exchangeName: {{ .Values.config.workQueue.jobQueue.exchangeName }}
      workerPrefetchCount: {{ .Values.config.workQueue.jobQueue.workerPrefetchCount }}
      workerPrefetchSize: {{ .Values.config.workQueue.jobQueue.workerPrefetchSize }}
      routingKey: {{ .Values.config.workQueue.jobQueue.routingKey }}
{{- if .Values.config.workQueue.jobQueue.maxTTL }}
      maxTTL: {{ .Values.config.workQueue.jobQueue.maxTTL }}
{{- end }}
{{- if .Values.config.workQueue.jobQueue.deadLetterExchange }}
      deadLetterExchange: {{ .Values.config.workQueue.jobQueue.deadLetterExchange }}
{{- end }}
{{- if .Values.config.workQueue.jobQueue.deadLetterRoutingKey }}
      deadLetterRoutingKey: {{ .Values.config.workQueue.jobQueue.deadLetterRoutingKey }}
{{- end }}
    waitingQueue:
      deadLetterEnabled: {{ .Values.config.workQueue.waitingQueue.deadLetterEnabled }}
      queueName: {{ .Values.config.workQueue.waitingQueue.queueName }}
      exchangeName: {{ .Values.config.workQueue.waitingQueue.exchangeName }}
      workerPrefetchCount: {{ .Values.config.workQueue.waitingQueue.workerPrefetchCount }}
      workerPrefetchSize: {{ .Values.config.workQueue.waitingQueue.workerPrefetchSize }}
      routingKey: {{ .Values.config.workQueue.waitingQueue.routingKey }}
      maxTTL: {{ .Values.config.workQueue.waitingQueue.maxTTL }}
      deadLetterExchange: {{ .Values.config.workQueue.waitingQueue.deadLetterExchange }}
      deadLetterRoutingKey: {{ .Values.config.workQueue.waitingQueue.deadLetterRoutingKey }}
{{- end }}
{{- if .Values.config.smtpBackends }}
  # extra SMTP backends and a list of recipient domains
  smtpBackends:
{{- range $v := .Values.config.smtpBackends }}
    - name: {{ $v.name }}
{{- if $v.host }}
      host: {{$v.host }}
{{- end }}
{{- if $v.hosts }}
      hosts:
{{- range $k, $v := $v.hosts }}
        {{ $k }}:
{{- range $v := $v }}
          - {{ $v }}
{{- end }}
{{- end }}
{{- end }}
{{- if $v.domains }}
      domains:
{{- range $kd, $vd := $v.domains }}
        - {{ $vd }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- if .Values.config.blockedDomains }}
  # blocked sender domains
  # TODO: delete after upgrade
  blockedDomains:
{{- range $k, $v := .Values.config.blockedDomains }}
    - {{ $v }}
{{- end }}
    - {{ .Values.config.verifyEmailDomain }}
{{- end }}
{{- $requestValidate := .Values.global.requestValidate }}
{{- if not $requestValidate }}
{{- $requestValidate = .Values.config.requestValidate }}
{{- end }}
{{- if $requestValidate }}
  requestValidate:
    blockedDomains:
{{- range $k, $v := $requestValidate.blockedDomains }}
      - {{ $v }}
{{- end }}
{{- if $requestValidate.auditHeaders }}
    auditHeaders:
{{- range $k, $v := $requestValidate.auditHeaders }}
      {{ $k }}: {{ $v }}
{{- end }}
{{- end }}
{{- if $requestValidate.originatorHeaders }}
    originatorHeaders:
{{- range $k, $v := $requestValidate.originatorHeaders }}
      {{ $k }}: {{ $v }}
{{- end }}
{{- end }}
{{- if $requestValidate.sesV1CheckKeys }}
    sesV1CheckKeys:
{{- range $k, $v := $requestValidate.sesV1CheckKeys }}
      {{ $k }}: {{ $v | toJson }}
{{- end }}
{{- end }}
{{- if $requestValidate.sesV2CheckKeys }}
    sesV2CheckKeys:
{{- range $k, $v := $requestValidate.sesV2CheckKeys }}
      - {{ quote $v}}
{{- end }}
{{- end }}
{{- if $requestValidate.sesV2ForbidURLs }}
    sesV2ForbidURLs:
{{- range $k, $v := $requestValidate.sesV2ForbidURLs }}
      {{ quote $k }}:
{{- range $k, $v := $v }}
        - {{ $v }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
  debug: {{ .Values.cronus.debug }}
  policy:
{{- range $key, $value := .Values.config.cronusPolicy }}
    {{ $key }}: {{ $value }}
{{- end }}
{{- if .Values.hermes }}
{{- $user := .Values.rabbitmq_notifications.users.default.user }}
{{- $password := .Values.rabbitmq_notifications.users.default.password }}
{{- $host := printf "%s.%s.%s:5672" "hermes-rabbitmq-notifications" .Values.global.region .Values.global.tld }}
  auditSink:
    rabbitmqUrl: amqp://{{ $user }}:{{ $password }}@{{ if .Values.config.cronusAuditSink.host }}{{ .Values.config.cronusAuditSink.host }}{{ else }}{{ $host }}{{ end }}
    queueName: {{ .Values.config.cronusAuditSink.queueName }}
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
