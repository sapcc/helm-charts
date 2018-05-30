[DEFAULT]

# Make sure your swift-ring-builder arguments match the bind_ip and bind_port.
# You almost certainly do not want to listen just on loopback unless testing.
# However, you want to keep port 6200 if SElinux is enabled.
bind_ip = 0.0.0.0
bind_port = 6000

workers = 12
max_clients = 1024
backlog = 8192
client_timeout = {{ .Values.client_timeout }}
log_statsd_host = localhost
log_statsd_port = 9125
log_statsd_default_sample_rate = 1.0
log_statsd_sample_rate_factor = 1.0
log_statsd_metric_prefix = swift
{{ if .Values.debug -}}
log_level = DEBUG
{{- else -}}
log_level = INFO
{{- end }}

[pipeline:main]
pipeline = healthcheck recon object-server

[app:object-server]
use = egg:swift#object
{{- if .Values.s3api_enabled }}
allowed_headers = Cache-Control, Content-Disposition, Content-Encoding, Content-Language, Expires, X-Delete-At, X-Object-Manifest, X-Robots-Tag, X-Static-Large-Object
{{- else}}
allowed_headers = Content-Disposition, Content-Encoding, X-Delete-At, X-Object-Manifest, X-Static-Large-Object
{{- end}}

[object-replicator]
concurrency = {{ .Values.object_replicator_concurrency }}

[object-updater]
interval = 60
concurrency = {{ .Values.object_updater_concurrency }}

[object-auditor]


[filter:healthcheck]
use = egg:swift#healthcheck
disable_path = /etc/swift/healthcheck/object.disabled


[filter:recon]
use = egg:swift#recon
recon_lock_path = /var/run/swift
