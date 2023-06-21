{{- define "mosquitto_v2.conf" -}}
log_dest stderr #stdout is buffered without tty somehow on v2
log_timestamp true
log_timestamp_format %Y-%m-%dT%H:%M:%S
connection_messages true
per_listener_settings true
# The default listener only listens on localhost for metrics collection
listener 1883 127.0.0.1
allow_anonymous true

{{- if .Values.tls.enabled }}
# TLS listener
listener {{ .Values.service.internalPort }} 0.0.0.0
auth_plugin /usr/local/lib/mosquitto-auth.so
require_certificate true
use_subject_as_username true
use_username_as_clientid true
cafile /mosquitto_tls/ca.crt
certfile /mosquitto_tls/tls.crt
keyfile /mosquitto_tls/tls.key
{{- if .Values.tls.crl }}
crlfile /mosquitto/ca.crl
{{- end }}
{{- end }}
{{- end }}
