[secretstore]
enable_multiple_secret_stores = True
stores_lookup_suffix = software{{- if .Values.hsm.multistore.enabled }}, pkcs11{{- end }}{{- if .Values.hsm.thales_multitenancy.enabled }}, thales_hsm{{- end }}{{- if .Values.hsm.utimaco_multitenancy.enabled }}, utimaco_hsm{{- end }}
namespace = barbican.secretstore.plugin

[secretstore:software]
secret_store_plugin = store_crypto
crypto_plugin = simple_crypto

{{- if .Values.hsm.multistore.enabled }}
[secretstore:pkcs11]
secret_store_plugin = store_crypto
crypto_plugin = p11_crypto
global_default = True
{{- end }}

{{- if .Values.hsm.thales_multitenancy.enabled }}
[secretstore:thales_hsm]
secret_store_plugin = store_crypto
crypto_plugin = hsm_partition_crypto
{{- end }}