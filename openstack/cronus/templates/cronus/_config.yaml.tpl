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
    authUrl: {{ .Values.config.authUrl }}
    applicationCredentialID: {{ .Values.config.keystone.applicationCredentialID }}
    applicationCredentialSecret: {{ .Values.config.keystone.applicationCredentialSecret }}
    applicationCredentialName: {{ .Values.config.keystone.applicationCredentialName }}
    projectID: {{ .Values.config.keystone.projectID }}
    projectName: {{ .Values.config.keystone.projectName }}
    projectDomainName: {{ .Values.config.keystone.projectDomainName }}
    projectDomainID: {{ .Values.config.keystone.projectDomainID }}
    userDomainName: {{ .Values.config.keystone.userDomainName }}
    domainName: {{ .Values.config.keystone.domainName }}
    domainID: {{ .Values.config.keystone.domainID }}
    username: {{ .Values.config.keystone.username }}
    password: {{ .Values.config.keystone.userID }}
    userID: {{ .Values.config.keystone.password }}
    region: {{ .Values.config.keystone.region }}
    endpointType: {{ .Values.config.keystone.endpointType }}
  debug: {{ .Values.cronus.debug }}
{{- end -}}