{{ define "nova.etc_config_lua" }}
local _M = {}
_M.dbs = {
    { host = '{{ include "nova.helpers.cell01_db" . }}.{{ include "svc_fqdn" . }}',
    user = '{{ .Values.dbUser | include "resolve_secret" }}',
    password = '{{ default .Values.dbPassword .Values.global.dbPassword | include "resolve_secret" }}',
    database = '{{ .Values.dbName }}',
    charset = 'utf8' },
{{- if .Values.cell2.enabled }}
    { host = '{{ include "nova.helpers.cell2_db" }}.{{ include "svc_fqdn" . }}',
    user = '{{ .Values.cell2dbUser | include "resolve_secret" }}',
    password = '{{ default .Values.cell2dbPassword .Values.global.dbPassword | include "resolve_secret" }}',
    database = '{{ .Values.cell2dbName }}',
    charset = 'utf8' },
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
