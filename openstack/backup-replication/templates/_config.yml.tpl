{{- define "config.yml" -}}
from:
  os_auth_url: {{ .Values.from.os_auth_url | quote }}
  os_auth_version: {{ .Values.from.os_auth_version | quote }}
  os_username: {{ .Values.from.os_username | quote }}
  os_user_domain: {{ .Values.from.os_user_domain | quote }}
  os_project_name: {{ .Values.from.os_project_name | quote }}
  os_project_domain: {{ .Values.from.os_project_domain | quote }}
  os_region_name: {{ .Values.from.os_region_name | quote }}
  os_password: {{ .Values.from.os_password | quote }}
to:
{{- range $key, $val := .Values.to }}
  - os_auth_url: {{ $val.os_auth_url | quote }}
    os_auth_version: {{ $val.os_auth_version | quote }}
    os_username: {{ $val.os_username | quote }}
    os_user_domain: {{ $val.os_user_domain | quote }}
    os_project_name: {{ $val.os_project_name | quote }}
    os_project_domain: {{ $val.os_project_domain | quote }}
    os_region_name: {{ $val.os_region_name | quote }}
    os_password: {{ $val.os_password | quote }}
{{- end }}
{{- end -}}
