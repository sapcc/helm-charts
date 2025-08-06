{{ define "nova.etc_config_lua" }}
local _M = {}
_M.dbs = {
{{- $contextCell1 := dict "target" "cell1" "defaultUsers" .Values.defaultUsersMariaDB "users" .Values.mariadb.users }}
    { host = '{{ .Release.Name }}-mariadb.{{ include "svc_fqdn" . }}',
    user = '{{ (include "nova.helpers.default_db_user" $contextCell1) | include "resolve_secret" }}',
    password = '{{ (include "nova.helpers.default_user_password" $contextCell1) | include "resolve_secret" }}',
    database = 'nova',
    charset = 'utf8' },
{{- if .Values.cell2.enabled }}
{{- $contextCell2 := dict "target" "cell2" "defaultUsers" .Values.defaultUsersMariaDB "users" .Values.mariadb_cell2.users }}
    { host = '{{ .Release.Name }}-{{ .Values.cell2.name }}-mariadb.{{ include "svc_fqdn" . }}',
    user = '{{ (include "nova.helpers.default_db_user" $contextCell2) | include "resolve_secret" }}',
    password = '{{ (include "nova.helpers.default_user_password" $contextCell2) | include "resolve_secret" }}',
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
