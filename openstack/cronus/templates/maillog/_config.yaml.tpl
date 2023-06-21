{{- if .Values.maillog.enabled -}}
maillog:
  debug: {{ .Values.maillog.debug }}
  storage:
    type: {{ .Values.maillog.storage.type | default "elasticsearch" }} # allowed: elasticsearch, opensearch
    uri: {{ .Values.maillog.storage.uri | quote }}
    username: {{ .Values.maillog.storage.username | quote }}
    password: {{ .Values.maillog.storage.password | quote }}
    indexMgmt: {{ .Values.maillog.storage.indexMgmt | default false }}
    indexPrefix: {{ .Values.maillog.storage.indexPrefix | default "mailstate" }}
    indexDateFormat: {{ .Values.maillog.storage.indexDateFormat | default "2006_02_01_15_04_05" }}
    cutOffTime: {{ .Values.maillog.storage.cutOffTime | default "30d" }}
    granularity: {{ .Values.maillog.storage.granularity | default "1d"  }}
    lookBacks: {{ .Values.maillog.storage.lookbacks | default 5 }} # update active mail states up to x * granularity
  headers: # Specify which headers we want to keep
{{- range $key, $value := .Values.maillog.headers }}
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
{{- range $key, $value := .Values.maillog.policy }}
      {{ $key }}: {{ $value }}
{{- end }}
  server:
    http: {{ .Values.maillog.server.http }}
    maxRequestSize: {{ mul (.Values.maillog.server.maxRequestSize | default .Values.global.maxBodySize) 1 }}
{{- if .Values.maillog.tls }}
    tls:
      namespace: {{ .Values.maillog.tls.namespace | default "maillog" }}
      serverTlsName: {{ .Values.maillog.tls.serverTlsName }}
{{- if or .Values.maillog.tls.clientCA .Values.global.clientCA .Values.maillog.tls.clientTlsAuth .Values.global.clientTlsAuth }}
      clientTlsAuth: {{ .Values.maillog.tls.clientTlsAuth | default .Values.global.clientTlsAuth }}
{{- if or .Values.maillog.tls.clientCertOU .Values.global.clientCertOU }}
      clientCertOU: {{ .Values.maillog.tls.clientCertOU | default .Values.global.clientCertOU }}
{{- end }}
      clientCA: |
{{ .Values.maillog.tls.clientCA | default .Values.global.clientCA | indent 8 }}
{{- end }}
      errInterval: {{ .Values.maillog.tls.errInterval | default "60s" }}
{{- end }}
{{- end -}}