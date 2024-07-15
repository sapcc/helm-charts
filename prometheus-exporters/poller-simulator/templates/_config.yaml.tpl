{{- if .Values.simulator.poller.enabled -}}
poller:
  prometheusPort: {{ .Values.simulator.poller.prometheusPort }}
  action: {{ .Values.simulator.poller.action }}
  pollInterval: {{ .Values.simulator.poller.pollInterval }}
  maxThreads: {{ .Values.simulator.poller.maxThreads }}
  maxSendThreads: {{ .Values.simulator.poller.maxSendThreads }}
  maxBounceThreads: {{ .Values.simulator.poller.maxBounceThreads }}
  bounceSender: {{ .Values.simulator.poller.bounceSender }}
  mtaName: {{ .Values.simulator.poller.mtaName }}
  quarContainer:
    name: {{ .Values.simulator.poller.quarContainer.name }}
  errContainer:
    name: {{ .Values.simulator.poller.errContainer.name }}
  prettyPrint: {{ .Values.simulator.poller.prettyPrint }}
  printMessage: {{ .Values.simulator.poller.printMessage }}
  queueName: {{ .Values.simulator.poller.queueName }}
  {{- if .Values.simulator.poller.emailPassVerdicts.enabled }}
  emailPassVerdicts:
    spam:
    {{- range $key, $value := .Values.simulator.poller.emailPassVerdicts.spam }}
      - {{ $value }}
    {{- end }}
    virus:
    {{- range $key, $value := .Values.simulator.poller.emailPassVerdicts.virus }}
      - {{ $value }}
    {{- end }}
    spf:
    {{- range $key, $value := .Values.simulator.poller.emailPassVerdicts.spf }}
      - {{ $value }}
    {{- end }}
    dkim:
    {{- range $key, $value := .Values.simulator.poller.emailPassVerdicts.dkim }}
      - {{ $value }}
    {{- end }}
    dmarc:
    {{- range $key, $value := .Values.simulator.poller.emailPassVerdicts.dmarc }}
      - {{ $value }}
    {{- end }}
  {{- end }}
  debug: {{ .Values.simulator.poller.debug }}
  retry:
    {{- range $key, $value := .Values.simulator.poller.retry }}
    {{ $key }}: {{ $value }}
  {{- end }}
  {{- if .Values.simulator.poller.endpoint.enabled }}
  endpoint: {{ .Values.simulator.poller.endpoint.name }}
  {{- end -}}
  {{- if .Values.simulator.poller.aws.enabled }}
  aws:
  {{- range $key, $value := .Values.simulator.poller.aws }}
    {{ $key }}: {{ $value }}
  {{- end -}}
  {{- end -}}
  {{- if .Values.simulator.poller.dnsResolvers.enabled }}
  dnsResolvers:
  {{- range $k, $v := .Values.simulator.poller.dnsResolvers.dns }}
    - {{ $v }}
  {{- end -}}
  {{- end -}}
  {{- if .Values.simulator.poller.ldap.enabled }}
  ldap:
  {{- range $key, $value := .Values.simulator.poller.ldap }}
    {{ $key }}: {{ $value }}
  {{- end -}}
  {{- end -}}
  {{- if .Values.simulator.poller.keystone.enabled }}

  keystone:
    authUrl: {{ .Values.simulator.poller.keystone.authUrl }}
    endpointType: {{ .Values.simulator.poller.keystone.endpointType }}
    projectDomainName: {{ .Values.simulator.poller.keystone.projectDomainName }}
    projectName: {{ .Values.simulator.poller.keystone.projectName }}
    region: {{ .Values.simulator.poller.keystone.region }}
    userDomainName: {{ .Values.simulator.poller.keystone.userDomainName }}
    username: {{ .Values.simulator.poller.keystone.username }}
  {{- end -}}
  {{- if eq .Values.simulator.poller.action "simulator" }}
  simulator:
    region: {{ .Values.config.keystone.region }}
    loader: {{ .Values.simulator.poller.loader }}
    simulatorTests:
    {{- range .Values.simulator.poller.simulatorTests }}
    - test:
    {{- range $k, $v := . }}
    {{- if and (ne $k "ec2Secret") (ne $k "smtpPassword") (ne $k "ec2User") }}
      {{ $k }}: {{ $v }}
    {{- end }}
    {{- end }}
    {{- end }}
    executionTime: {{ .Values.simulator.poller.executionTime }}
    loaderThreads: {{ .Values.simulator.poller.loaderThreads }}
    sleepDuration: {{ .Values.simulator.poller.sleepDuration }}
    sleepThreads: {{ .Values.simulator.poller.sleepThreads }}
    smtpHost: cronus.{{ .Values.config.keystone.region }}.cloud.sap
    sesApiEndpoint: https://cronus.{{ .Values.config.keystone.region }}.cloud.sap
    sesRegion: {{ .Values.config.allowedServices.email }}
    envelopeFrom: {{ .Values.simulator.poller.envelopeFrom }}
    {{- if .Values.simulator.poller.headerFrom }}
    headerFrom: {{ .Values.simulator.poller.headerFrom }}
    {{- end }}
    insecureTLS: {{ .Values.simulator.poller.insecureTLS }}


    recipients:
    {{- range $key, $value := .Values.simulator.poller.recipients }}
     - {{ $value }}
    {{- end }}
    prometheus: {{ .Values.simulator.poller.prometheus }}
    charSet: {{ .Values.simulator.poller.charSet }}
    period: {{ .Values.simulator.poller.period }}
    tests:
    {{- range $key, $value := .Values.simulator.poller.tests }}
     - {{ $value }}
  {{- end }}
  {{- end }}
{{- end -}}