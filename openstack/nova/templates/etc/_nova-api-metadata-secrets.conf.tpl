[neutron]
{{- if kindIs "string" .Values.global.nova_metadata_secret }}
metadata_proxy_shared_secret = {{ .Values.global.nova_metadata_secret | include "resolve_secret" }}
{{- else }}
{{- range $secret := .Values.global.nova_metadata_secret }}
metadata_proxy_shared_secret = {{ $secret | include "resolve_secret" }}
{{- end }}
{{- end }}
