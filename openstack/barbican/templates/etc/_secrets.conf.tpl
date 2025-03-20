[DEFAULT]

{{ include "ini_sections.default_transport_url" . }}

[database]
connection = {{ include "utils.db_url" . }}

[keystone_authtoken]
username = {{ .Release.Name }}
password = {{ required ".Values.global.barbican_service_password is missing" .Values.global.barbican_service_password | include "resolve_secret" }}

{{ include "ini_sections.audit_middleware_notifications" . }}

{{- if .Values.hsm.multistore.enabled }}
[p11_crypto_plugin]
library_path = {{ .Values.lunaclient.conn.library_path }}
login = {{ .Values.lunaclient.conn.login | include "resolve_secret" }}
mkek_label = {{ .Values.lunaclient.conn.mkek_label | include "resolve_secret" }}
mkek_length = {{ .Values.lunaclient.conn.mkek_length }}
hmac_label = {{ .Values.lunaclient.conn.hmac_label | include "resolve_secret" }}
slot_id = {{ .Values.lunaclient.conn.slot_id }}
encryption_mechanism = {{ .Values.lunaclient.conn.encryption_mechanism }}
# hmac_key_type = {{ .Values.lunaclient.conn.hmac_key_type }} --> need to be enabled if new keys are generated
# hmac_keygen_mechanism = {{ .Values.lunaclient.conn.hmac_keygen_mechanism }}
hmac_mechanism = {{ .Values.lunaclient.conn.hmac_mechanism }}
key_wrap_mechanism = {{ .Values.lunaclient.conn.key_wrap_mechanism }}
aes_gcm_generate_iv = {{ .Values.lunaclient.conn.aes_gcm_generate_iv }}
{{- end }}
