{{- if .Values.hsm.thales_multitenancy.enabled }}
[secretstore:thales_hsm]
secret_store_plugin = store_crypto
crypto_plugin = hsm_partition_crypto
{{- end }}