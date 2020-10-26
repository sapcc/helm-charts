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
    http: :{{ .Values.cronus.port.http }} # default :5000
    smtp: :{{ .Values.cronus.port.smtp }} # default :1025
  keystone:
{{- range $key, $value := .Values.config.keystone }}
  {{- if $value }}
    {{ $key }}: {{ $value }}
  {{- end }}
{{- end }}
  debug: {{ .Values.cronus.debug }}
{{- end -}}