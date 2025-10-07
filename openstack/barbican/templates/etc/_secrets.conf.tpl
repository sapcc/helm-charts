[DEFAULT]

[database]
connection = {{ include "utils.db_url" . }}

[keystone_authtoken]
username = {{ .Release.Name }}
password = {{ required ".Values.global.barbican_service_password is missing" .Values.global.barbican_service_password | include "resolve_secret" }}

{{ include "ini_sections.audit_middleware_notifications" . }}

{{- if .Values.hsm.multistore.enabled }}
[p11_crypto_plugin]
library_path = /utimaco/lib/libcs_pkcs11_R3.so
login = ox6t6U3I
mkek_label = qade3_mkek_utimaco
mkek_length = 32
hmac_label = qade3_hmac_utimaco
slot_id = 0
encryption_mechanism = CKM_AES_CBC
{{- end }}
