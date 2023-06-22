{{- define "maillog-config" -}}
maillog:
  debug: {{ .Values.debug }}
  storage:
    type: {{ .Values.storage.type | default "elasticsearch" }} # allowed: elasticsearch, opensearch
    uri: {{ .Values.storage.uri | quote }}
    username: {{ .Values.storage.username | quote }}
    password: {{ .Values.storage.password | quote }}
    indexMgmt: {{ .Values.storage.indexMgmt | default false }}
    indexPrefix: {{ .Values.storage.indexPrefix | default "mailstate" | quote }}
    indexDateFormat: {{ .Values.storage.indexDateFormat | default "2006_02_01_15_04_05" | quote }}
    cutOffTime: {{ .Values.storage.cutOffTime | default "720h" | quote }}
    granularity: {{ .Values.storage.granularity | default "24h"  | quote}}
    lookBacks: {{ .Values.storage.lookbacks | default 5 }} # update active mail states up to x * granularity
  headers: # Specify which headers we want to keep
{{- range $key, $value := .Values.headers }}
    - {{ $value | quote }}
{{- end }}
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
{{- range $key, $value := .Values.policy }}
      {{ $key }}: {{ $value }}
{{- end }}
  server:
    http: {{ .Values.server.http }}
    maxRequestSize: {{ mul (.Values.server.maxRequestSize | default .Values.global.maxBodySize) 1 }}
{{- if .Values.tls }}
    tls:
      namespace: {{ .Values.tls.namespace | default "maillog" }}
      serverTlsName: {{ .Values.tls.serverTlsName }}
{{- if or .Values.tls.clientCA .Values.global.clientCA .Values.tls.clientTlsAuth .Values.global.clientTlsAuth }}
      clientTlsAuth: {{ .Values.tls.clientTlsAuth | default .Values.global.clientTlsAuth }}
{{- if or .Values.tls.clientCertOU .Values.global.clientCertOU }}
      clientCertOU: {{ .Values.tls.clientCertOU | default .Values.global.clientCertOU }}
{{- end }}
      clientCA: |
{{ .Values.tls.clientCA | default .Values.global.clientCA | indent 8 }}
{{- end }}
      errInterval: {{ .Values.tls.errInterval | default "60s" }}
{{- end }}
{{- end -}}
