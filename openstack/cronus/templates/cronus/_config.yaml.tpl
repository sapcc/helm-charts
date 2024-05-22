{{- if .Values.cronus.enabled -}}
cronus:
  ttlReject: {{ .Values.global.ttlReject }}
  hostname: cronus.{{ .Values.global.region }}.{{ .Values.global.tld }}
  cacheSize: {{ .Values.cronus.cacheSize }}
  billingCacheTTL: {{ .Values.config.billingCacheTTL }}
  barbicanCacheTTL: {{ .Values.config.barbicanCacheTTL }}
  awsSignV2TTL: {{ .Values.config.awsSignV2TTL }}
{{- if .Values.cronus.allowedNdrs }}
  allowedNdrs:
  {{- range $v := .Values.cronus.allowedNdrs }}
    - projectId: {{ $v.projectId }}
    {{- if $v.backend }}
      backend: {{$v.backend | quote }}
    {{- end }}
    {{- if $v.routing }}
      routing: {{$v.routing }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if .Values.cronus.inspections }}
  inspections:
  {{- range $v := .Values.cronus.inspections }}
    - name: {{ $v.name }}
    {{- if $v.projectId }}
      projectId: {{$v.projectId | quote }}
    {{- end }}
    {{- if $v.errorCase }}
      errorCase: {{$v.errorCase | quote }}
    {{- end }}
    {{- if $v.errorCode }}
      errorCode: {{ $v.errorCode }}
    {{- end }}
  {{- end }}
{{- end }}
{{- if .Values.cronus.ndr }}
  ndr:
    rheaUri: {{ .Values.cronus.ndr.rheaUri | quote }}
    queue: {{ .Values.cronus.ndr.queue | quote }}
{{- end }}
{{- if .Values.cronus.maillog }}
  maillog:
    uri: {{ .Values.cronus.maillog.uri | quote }}
{{- end }}
{{- if or .Values.cronus.fileBufferPath .Values.global.fileBufferPath }}
  fileBufferPath: {{ .Values.cronus.fileBufferPath | default .Values.global.fileBufferPath }}
{{- end }}
{{- if .Values.config.retry }}
  retry:
{{- if .Values.config.retry.maxConnectionRetries }}
    maxConnectionRetries: {{ .Values.config.retry.maxConnectionRetries }}
{{- end }}
{{- if .Values.config.retry.retryInterval }}
    retryInterval: {{ .Values.config.retry.retryInterval }}
{{- end }}
{{- if .Values.config.retry.connectionTimeout }}
    connectionTimeout: {{ .Values.config.retry.connectionTimeout }}
{{- end }}
{{- if .Values.config.retry.commandTimeout }}
    commandTimeout: {{ .Values.config.retry.commandTimeout }}
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
    prometheus: :{{ .Values.cronus.prometheus }} # default :2772
{{- if .Values.cronus.listenProxyProtocol }}
    proxyProtocol: {{ .Values.cronus.listenProxyProtocol }}
{{- end }}
{{- if .Values.cronus.proxyHeaderTimeout }}
    proxyHeaderTimeout: {{ .Values.cronus.proxyHeaderTimeout }}
{{- end }}
{{- if .Values.cronus.skipProxyForCIDR }}
    skipProxyForCIDR: {{ .Values.cronus.skipProxyForCIDR }}
{{- end }}
    shutdownTimeout: {{ .Values.cronus.terminationGracePeriod | default 60 }}s
    readTimeout: {{ .Values.cronus.readTimeout | default 30 }}s
    writeTimeout: {{ .Values.cronus.writeTimeout | default 30 }}s
    keepAliveTimeout: {{ .Values.cronus.keepAliveTimeout | default 60 }}s
{{- if or .Values.cronus.maxBodySize .Values.global.maxBodySize }}
    maxBodySize: {{ mul (.Values.cronus.maxBodySize | default .Values.global.maxBodySize) 1 }}
{{- end }}
{{- if .Values.cronus.tls }}
{{- if .Values.cronus.smtps }}
    startTls: :{{ .Values.cronus.smtps }} # default :587
{{- end }}
    tls:
      namespace: {{ .Values.cronus.tls.namespace | default "cronus" }}
      serverTlsName: {{ .Values.cronus.tls.serverTlsName }}
{{- if or .Values.cronus.tls.clientCA .Values.global.clientCA .Values.cronus.tls.clientTlsAuth .Values.global.clientTlsAuth }}
      clientTlsAuth: {{ .Values.cronus.tls.clientTlsAuth | default .Values.global.clientTlsAuth }}
      clientCA: |
{{ .Values.cronus.tls.clientCA | default .Values.global.clientCA | indent 8 }}
{{- end }}
      errInterval: {{ .Values.cronus.tls.errInterval | default "60s" }}
{{- end }}
  keystone:
{{- if .Values.config.keystone }}
    region: {{ .Values.config.keystone.region }}
    authUrl: {{ .Values.config.keystone.authUrl }}
    endpointType: {{ .Values.config.keystone.endpointType }}
    username: {{ .Values.config.keystone.username }}
    userDomainName: {{ .Values.config.keystone.userDomainName }}
    projectName: {{ .Values.config.keystone.projectName }}
    projectDomainName: {{ .Values.config.keystone.projectDomainName }}
    enabled: {{ .Values.config.keystone.enabled }}
{{- end }}
{{- else }}
    authUrl: {{ .Values.config.authUrl }}
    applicationCredentialID: {{ .Values.config.applicationCredentialID }}
    region: {{ .Values.config.region }}
    endpointType: {{ .Values.config.endpointType }}
{{- end }}
{{- if .Values.config.workQueue }}
  workQueue:
    enabled: {{ .Values.config.workQueue.enabled }}
{{- if .Values.config.workQueue.active }}
    active: {{ .Values.config.workQueue.active }}
{{- end }}
{{- if .Values.config.workQueue.allowTrigger }}
    allowTrigger: {{ .Values.config.workQueue.allowTrigger }}
{{- end }}
{{- if .Values.config.workQueue.sendNdrs }}
    sendNdrs: {{ .Values.config.workQueue.sendNdrs }}
{{- end }}
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
    initialDelayTime: {{ .Values.config.workQueue.initialDelayTime }}
    delayGrowthFactor: {{ .Values.config.workQueue.delayGrowthFactor }}
    maxDelayTime: {{ .Values.config.workQueue.maxDelayTime }}
{{- if .Values.config.workQueue.maxRandomDelayAddOnTime }}
    maxRandomDelayAddOnTime: {{ .Values.config.workQueue.maxRandomDelayAddOnTime }}
{{- end }}
    maxTotalQueueTime: {{ .Values.config.workQueue.maxTotalQueueTime }}
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
    - name: {{ $v.name | quote }}
{{- if $v.host }}
      host: {{$v.host }}
{{- end }}
{{- if $v.certPath }}
      certPath: {{$v.certPath }}
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
{{- if $v.domainsTo }}
      domainsTo:
{{- range $kd, $vd := $v.domainsTo }}
        - {{ $vd }}
{{- end }}
{{- end }}
{{- if $v.skipCredentials }}
      skipCredentials: {{ $v.skipCredentials }}
{{- end }}
{{- if $v.smtpConnPool }}
      smtpConnPool:
{{- if $v.smtpConnPool.maxConnGlobal }}
        maxConnGlobal: {{ $v.smtpConnPool.maxConnGlobal }}
{{- end }}
        maxConnPerProject: {{ $v.smtpConnPool.maxConnPerProject }}
        connTimeLimit: {{ $v.smtpConnPool.connTimeLimit }}
        connReuseLimit: {{ $v.smtpConnPool.connReuseLimit }}
{{- if $v.smtpConnPool.maxConnWaitTimeout }}
        maxConnWaitTimeout: {{ $v.smtpConnPool.maxConnWaitTimeout }}
{{- end }}
{{- if $v.smtpConnPool.maxConnReleaseTimeout }}
        maxConnReleaseTimeout: {{ $v.smtpConnPool.maxConnReleaseTimeout }}
{{- end }}
{{- end }}
{{- end }}
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
{{- if $requestValidate.allowedGetParams }}
    allowedGetParams:
{{- range $k, $v := $requestValidate.allowedGetParams }}
      - {{ $v }}
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
  auditSink:
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

