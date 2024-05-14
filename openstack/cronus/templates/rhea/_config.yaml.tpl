{{- if .Values.rhea.enabled -}}
rhea:
  debug: {{ .Values.rhea.debug }}
  auth:
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
    policy:
{{- range $key, $value := .Values.rhea.policy }}
      {{ $key }}: {{ $value }}
{{- end }}
  queue:
{{- $r_host := .Values.rhea_rabbitmq.host }}
{{- $r_user := .Values.rhea_rabbitmq.users.default.user }}
{{- $r_creds := .Values.rhea_rabbitmq.users.default.password }}
    uri: amqp://{{ $r_user }}:{{ $r_creds }}@{{ $r_host }}/
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
{{- if or .Values.rhea.tls.clientCertOU .Values.global.clientCertOU }}
      clientCertOU: {{ .Values.rhea.tls.clientCertOU | default .Values.global.clientCertOU }}
{{- end }}
      clientCA: |
{{ .Values.rhea.tls.clientCA | default .Values.global.clientCA | indent 8 }}
{{- end }}
      errInterval: {{ .Values.rhea.tls.errInterval | default "60s" }}
{{- end }}
{{- end -}}