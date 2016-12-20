{{- define "mosquitto.conf" -}}
log_dest stdout
log_timestamp true
connection_messages true
auth_plugin /usr/lib/mosquitto_auth_plugin_monsoon.so
port {{ .Values.service.internalPort }}
use_username_as_clientid true
{{- if .Values.tls.enabled }}
use_subject_as_username true
require_certificate true
cafile /mosquitto/ca.crt
certfile /mosquitto/server.crt
keyfile /mosquitto/server.key
{{- end }}
{{- end }}
