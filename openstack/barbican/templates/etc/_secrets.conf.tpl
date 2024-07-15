[DEFAULT]
sql_connection = {{ include "db_url_mysql" . }}

{{ include "ini_sections.default_transport_url" . }}


[keystone_authtoken]
username = {{ .Release.Name }}
password = {{ required ".Values.global.barbican_service_password is missing" .Values.global.barbican_service_password }}


{{ include "ini_sections.audit_middleware_notifications" . }}


{{- if .Values.hsm.multistore.enabled }}
[p11_crypto_plugin]
library_path = {{ .Values.lunaclient.conn.library_path }}
login = {{ .Values.lunaclient.conn.login }}
mkek_label = {{ .Values.lunaclient.conn.mkek_label }}
mkek_length = {{ .Values.lunaclient.conn.mkek_length }}
hmac_label = {{ .Values.lunaclient.conn.hmac_label }}
slot_id = {{ .Values.lunaclient.conn.slot_id }}
{{- end }}
