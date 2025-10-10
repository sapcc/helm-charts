[server]
database_path=mysql://{{ .Values.mariadb.users.kmip.user | include "resolve_secret" }}:{{ .Values.mariadb.users.kmip.password | include "resolve_secret" }}@{{include "kmip.db_host" . }}:3306/kmip
hostname=0.0.0.0
port=5696
certificate_path=/etc/pykmip/certs/server.crt
key_path=/etc/pykmip/certs/server.key
ca_path=/etc/pykmip/certs/ca.crt
auth_suite=TLS1.2
policy_path=/etc/pykmip/policies
enable_tls_client_auth=False
tls_cipher_suites= TLS_RSA_WITH_AES_128_CBC_SHA256 TLS_RSA_WITH_AES_256_CBC_SHA256 TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384
logging_level=DEBUG
