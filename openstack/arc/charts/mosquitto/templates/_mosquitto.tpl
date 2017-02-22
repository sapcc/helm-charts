{{- define "mosquitto.conf" -}}
log_dest stdout
log_timestamp true
connection_messages true
{{- if .Values.tls.enabled }}
# The default listener only listens on localhost for metrics collection
bind_address 127.0.0.1
port 1883
auth_plugin /usr/lib/mosquitto_auth_plugin_monsoon.so

# TLS listener
listener {{ .Values.service.internalPort }} 0.0.0.0
use_username_as_clientid true
use_subject_as_username true
require_certificate true
cafile /mosquitto/ca.crt
certfile /mosquitto/server.crt
keyfile /mosquitto/server.key
{{- end }}
{{- end }}
