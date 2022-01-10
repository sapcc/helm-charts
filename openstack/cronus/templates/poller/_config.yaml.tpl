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
  {{- range $key, $value := .Values.poller.keystone }}
    {{ $key }}: {{ $value }}
  {{- end -}}
  {{- end -}}
{{- end -}}