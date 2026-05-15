[DEFAULT]

[database]
connection = {{ include "utils.db_url" . }}

[keystone_authtoken]
username = {{ .Release.Name }}
password = {{ required ".Values.global.barbican_service_password is missing" .Values.global.barbican_service_password | include "resolve_secret" }}

{{ include "ini_sections.audit_middleware_notifications" . }}

{{- if .Values.hsm.multistore.enabled }}
[simple_crypto_plugin]
{{- range .Values.simple_crypto.kek }}
kek = {{ . | include "resolve_secret" }}
{{- end }}
{{- if .Values.simple_crypto.plugin_name }}
plugin_name = {{ .Values.simple_crypto.plugin_name }}
{{- end }}

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
pkek_cache_ttl = {{ .Values.lunaclient.conn.pkek_cache_ttl }}
pkek_cache_limit = {{ .Values.lunaclient.conn.pkek_cache_limit }}
{{- end }}

{{- if .Values.hsm.utimaco_hsm.enabled }}
[hsm_partition_crypto_plugin:utimaco_hsm]
library_path = {{ .Values.utimaco_hsm.library_path | include "resolve_secret" }}
login = {{ .Values.utimaco_hsm.login | include "resolve_secret" }}
mkek_label = {{ .Values.utimaco_hsm.mkek_label | include "resolve_secret" }}
mkek_length = 32
hmac_label = {{ .Values.utimaco_hsm.hmac_label | include "resolve_secret" }}
slot_id = 0
encryption_mechanism = {{ .Values.utimaco_hsm.encryption_mechanism }}
pkek_cache_ttl = {{ .Values.utimaco_hsm.pkek_cache_ttl }}
{{- end }}
