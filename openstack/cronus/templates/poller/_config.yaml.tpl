{{- if .Values.poller.enabled -}}
poller:
  action: {{ .Values.poller.action }}
  pollInterval: {{ .Values.poller.pollInterval }}
  maxThreads: {{ .Values.poller.maxThreads }}
  maxSendThreads: {{ .Values.poller.maxSendThreads }}
  maxBounceThreads: {{ .Values.poller.maxBounceThreads }}
  bounceSender: {{ .Values.poller.bounceSender }}
  mtaName: {{ .Values.poller.mtaName }}
  quarContainer:
    name: {{ .Values.poller.quarContainer.name }}
  errContainer:
    name: {{ .Values.poller.errContainer.name }}
  prettyPrint: {{ .Values.poller.prettyPrint }}
  printMessage: {{ .Values.poller.printMessage }}
  queueName: {{ .Values.poller.queueName }}
  {{- if .Values.poller.emailPassVerdicts.enabled }}
  emailPassVerdicts:
    spam:
    {{- range $key, $value := .Values.poller.emailPassVerdicts.spam }}
      - {{ $value }}
    {{- end }}
    virus:
    {{- range $key, $value := .Values.poller.emailPassVerdicts.virus }}
      - {{ $value }}
    {{- end }}
    spf:
    {{- range $key, $value := .Values.poller.emailPassVerdicts.spf }}
      - {{ $value }}
    {{- end }}
    dkim:
    {{- range $key, $value := .Values.poller.emailPassVerdicts.dkim }}
      - {{ $value }}
    {{- end }}
    dmarc:
    {{- range $key, $value := .Values.poller.emailPassVerdicts.dmarc }}
      - {{ $value }}
    {{- end }}
  {{- end }}
  debug: {{ .Values.poller.debug }}
  retry:
    {{- range $key, $value := .Values.poller.retry }}
    {{ $key }}: {{ $value }}
  {{- end }}
  {{- if .Values.poller.endpoint.enabled }}
  endpoint: {{ .Values.poller.endpoint.name }}
  {{- end -}}
  {{- if .Values.poller.aws.enabled }}
  aws:
  {{- range $key, $value := .Values.poller.aws }}
    {{ $key }}: {{ $value }}
  {{- end -}}
  {{- end -}}
  {{- if .Values.poller.dnsResolvers.enabled }}
  dnsResolvers:
  {{- range $k, $v := .Values.poller.dnsResolvers.dns }}
    - {{ $v }}
  {{- end -}}
  {{- end -}}
  {{- if .Values.poller.ldap.enabled }}
  ldap:
  {{- range $key, $value := .Values.poller.ldap }}
    {{ $key }}: {{ $value }}
  {{- end -}}
  {{- end -}}
  {{- if .Values.poller.keystone.enabled }}
  keystone:
    authUrl: {{ .Values.poller.keystone.authUrl }}
    endpointType: {{ .Values.poller.keystone.endpointType }}
    projectDomainName: {{ .Values.poller.keystone.projectDomainName }}
    projectName: {{ .Values.poller.keystone.projectName }}
    region: {{ .Values.poller.keystone.region }}
    userDomainName: {{ .Values.poller.keystone.userDomainName }}
    username: {{ .Values.poller.keystone.username }}
  {{- end -}}
  {{- if eq .Values.poller.action "simulator" }}
  simulator:
    region: {{ .Values.config.keystone.region }}
    smtpHost: cronus.{{ .Values.config.keystone.region }}.cloud.sap
    sesApiEndpoint: https://cronus.{{ .Values.config.keystone.region }}.cloud.sap
    sesRegion: {{ .Values.config.allowedServices.email }}
    recipient: {{ .Values.simulator.recipient }}
    sender: {{ .Values.simulator.sender }}
    prometheus: {{ .Values.poller.prometheus }}
    charSet: {{ .Values.poller.charSet }}
    period: {{ .Values.poller.period }}
  {{- end }}
{{- end -}}
