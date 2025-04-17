[secretstore]
enable_multiple_secret_stores = True
stores_lookup_suffix = utimaco_hsm
namespace = barbican.secretstore.plugin

[secretstore:software]
secret_store_plugin = store_crypto
crypto_plugin = simple_crypto

{{- if .Values.hsm.utimaco_multitenancy.enabled }}
[secretstore:utimaco_hsm]
secret_store_plugin = store_crypto
crypto_plugin = utimaco_hsm_crypto
{{- end }}