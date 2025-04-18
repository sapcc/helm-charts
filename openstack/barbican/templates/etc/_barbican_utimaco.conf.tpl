{{- if .Values.hsm.utimaco_multitenancy.enabled }}
[secretstore:utimaco_hsm]
secret_store_plugin = store_crypto
crypto_plugin = utimaco_hsm_crypto
{{- end }}