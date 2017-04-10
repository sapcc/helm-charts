{{- if .Values.store.swift.enabled }}
[swift-global]
auth_version = 3
{{- if .Values.keystone.auth_url }}
auth_address  = {{ .Values.keystone.auth_url }}
{{- else }}
auth_address  = {{ include "keystone_url" . }}/v3
{{- end }}

user =  {{ .Values.store.swift.projectName }}:{{ .Values.store.swift.username }}
key = {{ .Values.store.swift.password }}

{{- if .Values.store.swift.userDomainName }}
user_domain_name = {{ .Values.store.swift.userDomainName }}
{{- end }}
{{- if .Values.store.swift.userDomainId }}
user_domain_id = {{ .Values.store.swift.userDomainId }}
{{- end }}

{{- if .Values.store.swift.projectDomainName }}
project_domain_name = {{ .Values.store.swift.projectDomainName }}
{{- end }}
{{- if .Values.store.swift.projectDomainId }}
project_domain_id = {{ .Values.store.swift.projectDomainId }}
{{- end }}

{{- end }}
