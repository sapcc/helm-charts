[secretstore]
enable_multiple_secret_stores = True
stores_lookup_suffix = thales_hsm
namespace = barbican.secretstore.plugin

[secretstore:software]
secret_store_plugin = store_crypto
crypto_plugin = simple_crypto

{{- if .Values.hsm.thales_multitenancy.enabled }}
[secretstore:thales_hsm]
secret_store_plugin = store_crypto
crypto_plugin = hsm_partition_crypto
{{- end }}