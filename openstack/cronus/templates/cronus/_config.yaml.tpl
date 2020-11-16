{{- if .Values.cronus.enabled -}}
cronus:
  cacheSize: {{ .Values.cronus.cacheSize }}
  billingCacheTTL: {{ .Values.config.billingCacheTTL }}
  aws:
    forwardUserAgent: {{ .Values.config.forwardUserAgent }}
    allowedServices:
    {{- range $key, $value := .Values.config.allowedServices }}
      {{ $key }}: {{ $value }}
    {{- end }}
  listenAddr:
    http: :{{ .Values.cronus.http }} # default :5000
    smtp: :{{ .Values.cronus.smtp }} # default :1025
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
  debug: {{ .Values.cronus.debug }}
  policy:
    project_scope: project_id:%(project_id)s and (role:email_admin or role:email_user)
    domain_scope: domain_id:%(target.project.domain.id)s and (role:email_admin or role:email_user)
    cronus:usage_viewer: rule:project_scope or rule:domain_scope or role:cloud_email_admin or role:resource_service
    cronus:aws_proxy: rule:project_scope
    cronus:smtp_proxy: rule:project_scope
{{- end -}}
  metric:
    pushgatewayUrl: {{ .Values.config.pushgatewayUrl }}
    metricService: {{ .Values.config.cronus.metricService }}
