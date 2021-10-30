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
  {{- range $key, $value := .Values.simulator.poller.keystone }}
    {{ $key }}: {{ $value }}
  {{- end -}}
  {{- end -}}
  {{- if .Values.simulator.poller.keystone.enabled }}
  simulator:
    region: {{ .Values.config.keystone.region }}
    sesUsername: {{ .Values.simulator.sesUsername }}
    sesSecret: {{ .Values.simulator.sesSecret }}
    smtpPassword: {{ .Values.simulator.smtpPassword }}
    smtpHost: cronus.{{ .Values.config.keystone.region }}.cloud.sap
    sesApiEndpoint: https://cronus.{{ .Values.config.keystone.region }}.cloud.sap
    sesRegion: {{ .Values.config.allowedServices.email }}
    recipient: {{ .Values.simulator.recipient }}
    sender: {{ .Values.simulator.sender }}
  {{- end -}}
{{- end -}}