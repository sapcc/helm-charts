{{- $val := .Values.poller }}
{{- if $val.enabled -}}
poller:
  {{- if $val.prometheusPort }}
  prometheusPort: {{ $val.prometheusPort }}
  {{- end }}
  pollInterval: {{ $val.pollInterval }}
  maxThreads: {{ $val.maxThreads }}
  action: {{ $val.action }}
  debug: {{ $val.debug }}
  {{- if $val.endpoint }}
  endpoint: {{ $val.endpoint }}
  {{- end }}
  retry:
    maxConnectionRetries: {{ $val.retry.maxConnectionRetries }}
    retryInterval: {{ $val.retry.retryInterval }}
  dumpContainer:
    name: {{ $val.dumpContainer.name }}
  quarContainer:
    name: {{ $val.quarContainer.name }}
  errContainer:
    name: {{ $val.errContainer.name }}
  prettyPrint: {{ $val.prettyPrint }}
  printMessage: {{ $val.printMessage }}
  {{- if $val.rebuildDSN }}
  rebuildDSN: {{ $val.rebuildDSN }}
  {{- end }}
  {{- if $val.activateEmail }}
  activateEmail:
    signatureSecret: {{ $val.activateEmail.signatureSecret }}
    expirationTime: {{ $val.activateEmail.expirationTime }}
    domain: {{ $val.activateEmail.domain }}
  {{- end }}
  {{- if $val.forwardEmail }}
  forwardEmail:
    {{- if $val.forwardEmail.postgres }}
    postgres:
      dsn: {{ $val.forwardEmail.postgres.dsn }}
    {{- end }}
    maxSendThreads: {{ $val.forwardEmail.maxSendThreads }}
    maxBounceThreads: {{ $val.forwardEmail.maxBounceThreads }}
    bounceSender: {{ $val.forwardEmail.bounceSender }}
    mtaName: {{ $val.forwardEmail.mtaName }}
    smtpPorts:
    {{- range $v := $val.forwardEmail.smtpPorts }}
      - {{ $v }}
    {{- end }}
    {{- if $val.forwardEmail.localName }}
    localName: {{ $val.forwardEmail.localName }}
    {{- end }}
  {{- end }}
  {{- if $val.sesCredentials }}
  sesCredentials:
    {{- if $val.sesCredentials.aws }}
    aws:
    {{- range $k, $v := $val.sesCredentials.aws }}
      {{ $k }}: {{ $v }}
    {{- end }}
    {{- end }}
    {{- if $val.sesCredentials.keystone }}
    keystone:
    {{- range $k, $v := $val.sesCredentials.keystone }}
      {{ $k }}: {{ $v }}
    {{- end }}
    {{- end }}
    {{- if $val.sesCredentials.endpoint }}
    endpoint: {{ $val.sesCredentials.endpoint }}
    {{- end }}
  {{- end }}
  {{- if $val.rhea }}
  rhea:
    queueName: {{ $val.rhea.queueName }}
    uri: {{ $val.rhea.uri }}
    domainMode: {{ $val.rhea.domainMode }}
  {{- end }}
  {{- if $val.queueName }}
  queueName: {{ $val.queueName }}
  {{- end }}
  {{- if $val.emailPassVerdicts }}
  emailPassVerdicts:
    spam:
    {{- range $v := $val.emailPassVerdicts.spam }}
      - {{ $v }}
    {{- end }}
    virus:
    {{- range $v := $val.emailPassVerdicts.virus }}
      - {{ $v }}
    {{- end }}
    spf:
    {{- range $v := $val.emailPassVerdicts.spf }}
      - {{ $v }}
    {{- end }}
    dkim:
    {{- range $v := $val.emailPassVerdicts.dkim }}
      - {{ $v }}
    {{- end }}
    dmarc:
    {{- range $v := $val.emailPassVerdicts.dmarc }}
      - {{ $v }}
    {{- end }}
    {{- if $val.emailPassVerdicts.bouncePassVerdicts }}
    bouncePassVerdicts:
      spam:
      {{- range $v := $val.emailPassVerdicts.bouncePassVerdicts.spam }}
        - {{ $v }}
      {{- end }}
      virus:
      {{- range $v := $val.emailPassVerdicts.bouncePassVerdicts.virus }}
        - {{ $v }}
      {{- end }}
      spf:
      {{- range $v := $val.emailPassVerdicts.bouncePassVerdicts.spf }}
        - {{ $v }}
      {{- end }}
      dkim:
      {{- range $v := $val.emailPassVerdicts.bouncePassVerdicts.dkim }}
        - {{ $v }}
      {{- end }}
      dmarc:
      {{- range $v := $val.emailPassVerdicts.bouncePassVerdicts.dmarc }}
        - {{ $v }}
      {{- end }}
      fromRegexp:
      {{- range $v := $val.emailPassVerdicts.bouncePassVerdicts.fromRegexp }}
        - {{ $v }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if $val.aws }}
  aws:
    {{- range $k, $v := $val.aws }}
    {{ $k }}: {{ $v }}
    {{- end }}
  {{- end  }}
  {{- if $val.dnsResolvers }}
  dnsResolvers:
  {{- range $v := $val.dnsResolvers }}
    - {{ $v }}
  {{- end }}
  {{- end  }}
  {{- if $val.dnsResolversTimeouts }}
  dnsResolversTimeouts:
  {{- range $k, $v := $val.dnsResolversTimeouts }}
    {{ $k }}: {{ $v }}
  {{- end }}
  {{- end }}
  {{- if $val.dnsExpose }}
  dnsExpose: {{ $val.dnsExpose }}
  {{- end }}
  {{- if $val.ldap }}
  ldap:
  {{- range $k, $v := $val.ldap }}
    {{ $k }}: {{ $v }}
  {{- end }}
  {{- end }}
  {{- if $val.keystone }}
  keystone:
  {{- range $k, $v := $val.keystone }}
    {{ $k }}: {{ $v }}
  {{- end }}
  {{- end }} 
{{- end }}
