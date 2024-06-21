{{- if .Values.rhea.enabled -}}
rhea:
  debug: {{ .Values.rhea.debug }}
  auth:
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
{{ else }}
      authUrl: {{ .Values.config.authUrl }}
      applicationCredentialID: {{ .Values.config.applicationCredentialID }}
      applicationCredentialSecret: {{ .Values.config.applicationCredentialSecret }}
      region: {{ .Values.config.region }}
      endpointType: {{ .Values.config.endpointType }}
{{- end }}
    policy:
{{- range $key, $value := .Values.rhea.policy }}
      {{ $key }}: {{ $value }}
{{- end }}
  queue:
    maxTTL: {{ .Values.rhea.queue.maxTTL | default "0s" }}
    maxTries: {{ .Values.rhea.queue.maxTries | default 5 }}
    maxMessages: {{ .Values.rhea.queue.maxMessages | default 0 }}
  server:
    http: {{ .Values.rhea.server.http }}
    maxRequestSize: {{ mul (.Values.rhea.server.maxRequestSize | default .Values.global.maxBodySize) 1 }}
{{- if .Values.rhea.tls }}
    tls:
      namespace: {{ .Values.rhea.tls.namespace | default "cronus" }}
      serverTlsName: {{ .Values.rhea.tls.serverTlsName }}
{{- if or .Values.rhea.tls.clientCA .Values.global.clientCA .Values.rhea.tls.clientTlsAuth .Values.global.clientTlsAuth }}
      clientTlsAuth: {{ .Values.rhea.tls.clientTlsAuth | default .Values.global.clientTlsAuth }}
      clientCA: |
{{ .Values.rhea.tls.clientCA | default .Values.global.clientCA | indent 8 }}
{{- end }}
      errInterval: {{ .Values.rhea.tls.errInterval | default "60s" }}
{{- end }}
{{- end -}}