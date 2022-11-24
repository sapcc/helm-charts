{{ define "nova.etc_config_lua" }}
local _M = {}
_M.dbs = {
    { host = '{{ .Release.Name }}-mariadb.{{ include "svc_fqdn" . }}',
    user = '{{ .Values.mariadb.users.nova.name }}',
    password = '{{ .Values.mariadb.users.nova.password }}',
    database = 'nova',
    charset = 'utf8' },
{{- if .Values.cell2.enabled }}
    { host = '{{ .Release.Name }}-{{ .Values.cell2.name }}-mariadb.{{ include "svc_fqdn" . }}',
    user = '{{ .Values.cell2dbUser }}',
    password = '{{ default .Values.cell2dbPassword .Values.global.dbPassword }}',
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
