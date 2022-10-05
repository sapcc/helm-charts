[DEFAULT]

# Make sure your swift-ring-builder arguments match the bind_ip and bind_port.
# You almost certainly do not want to listen just on loopback unless testing.
# However, you want to keep port 6200 if SElinux is enabled.
bind_ip = 0.0.0.0
bind_port = 6000

workers = auto
{{- if .Values.object_servers_per_port }}
servers_per_port = {{ .Values.object_servers_per_port }}
{{- end }}
max_clients = 1024
backlog = 4096
client_timeout = {{ .Values.client_timeout }}

{{ include "swift_log_statsd" . }}
{{ if .Values.debug -}}
log_level = DEBUG
{{- else -}}
log_level = INFO
{{- end }}

fallocate_reserve = {{ .Values.fallocate_reserve }}

[pipeline:main]
pipeline = healthcheck recon object-server

[app:object-server]
use = egg:swift#object
set log_requests = {{ .Values.log_requests }}
{{- if .Values.s3api_enabled }}
allowed_headers = Cache-Control, Content-Disposition, Content-Encoding, Content-Language, Expires, X-Delete-At, X-Object-Manifest, X-Robots-Tag, X-Static-Large-Object
{{- else}}
allowed_headers = Content-Disposition, Content-Encoding, X-Delete-At, X-Object-Manifest, X-Static-Large-Object
{{- end}}

[object-replicator]
concurrency = {{ .Values.object_replicator_concurrency }}
replicator_workers = {{ .Values.object_replicator_workers }}
rsync_bwlimit = {{ .Values.object_replicator_rsync_bwlimit }}

[object-updater]
interval = 60
concurrency = {{ .Values.object_updater_concurrency }}
updater_workers = {{ .Values.object_updater_workers }}

[object-auditor]


[filter:healthcheck]
use = egg:swift#healthcheck
disable_path = /etc/swift/healthcheck/object.disabled


[filter:recon]
use = egg:swift#recon
recon_lock_path = /var/run/swift
