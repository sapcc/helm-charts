{{ define "nova.etc_config_lua" }}
local _M = {}
_M.dbs = {
    { host = '{{ include "nova.helpers.db_service" (tuple . "cell1") }}.{{ include "svc_fqdn" . }}',
    user = '{{ (include "nova.helpers.db_default_user" (tuple . "cell1")) | include "resolve_secret" }}',
    password = '{{ (include "nova.helpers.db_default_password" (tuple . "cell1")) | include "resolve_secret" }}',
    database = '{{ include "nova.helpers.db_database" (tuple . "cell1") }}',
    charset = 'utf8' },
{{- if .Values.cell2.enabled }}
    { host = '{{ include "nova.helpers.db_service" (tuple . "cell2") }}.{{ include "svc_fqdn" . }}',
    user = '{{ (include "nova.helpers.db_default_user" (tuple . "cell2")) | include "resolve_secret" }}',
    password = '{{ (include "nova.helpers.db_default_password" (tuple . "cell2")) | include "resolve_secret" }}',
    database = '{{ include "nova.helpers.db_database" (tuple . "cell2") }}',
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
