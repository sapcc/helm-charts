[neutron]
metadata_proxy_shared_secret = {{ .Values.global.nova_metadata_secret | include "resolve_secret" }}
