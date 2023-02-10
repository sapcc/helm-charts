{{- define "mosquitto.conf" -}}
log_dest stdout
log_timestamp true
connection_messages true
{{- if .Values.tls.enabled }}
# The default listener only listens on localhost for metrics collection
bind_address 127.0.0.1
port 1883
auth_plugin /usr/lib/mosquitto_auth_plugin_monsoon.so
auth_opt_acl_file /mosquitto/acl.conf

# TLS listener
listener {{ .Values.service.internalPort }} 0.0.0.0
use_username_as_clientid true
use_subject_as_username true
require_certificate true
cafile /mosquitto_tls/ca.crt
certfile /mosquitto_tls/tls.crt
keyfile /mosquitto_tls/tls.key
{{- end }}
{{- end }}
