{{ define "nova.etc_config_lua" }}
local _M = {}
_M.dbs = {
{{- $envAll := . }}
{{- range $cellId := include "nova.helpers.cell_ids_nonzero" . | fromJsonArray }}
{{- with $envAll }}
    { host = '{{ include "nova.helpers.db_service" (tuple . $cellId) }}.{{ include "svc_fqdn" . }}',
    user = '{{ (include "nova.helpers.db_default_user" (tuple . $cellId)) | include "resolve_secret" }}',
    password = '{{ (include "nova.helpers.db_default_password" (tuple . $cellId)) | include "resolve_secret" }}',
    database = '{{ include "nova.helpers.db_database" (tuple . $cellId) }}',
    charset = 'utf8' },
{{- end }}
{{- end }}
}

_M.memcached = {
{{- if .Values.memcached.host }}
    "{{ .Values.memcached.host }}", {{ .Values.memcached.port | default 11211 }}
{{- else }}
    "{{ .Chart.Name }}-memcached.{{ include "svc_fqdn" . }}", {{ .Values.memcached.memcached.port | default 11211 }}
{{- end }}
}

return _M
{{ end }}
