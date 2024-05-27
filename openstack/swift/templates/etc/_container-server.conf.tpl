[DEFAULT]

# Make sure your swift-ring-builder arguments match the bind_ip and bind_port.
# You almost certainly do not want to listen just on loopback unless testing.
# However, you want to keep port 6201 if SElinux is enabled.
bind_ip = 0.0.0.0
bind_port = 6001

workers = 8
max_clients = 1024
backlog = 4096

{{ include "swift_log_statsd" . }}
{{ if .Values.debug -}}
log_level = DEBUG
{{- else -}}
log_level = INFO
{{- end }}

fallocate_reserve = {{ .Values.fallocate_reserve }}

[pipeline:main]
pipeline = healthcheck recon container-server

[app:container-server]
use = egg:swift#container
set log_requests = {{ .Values.log_requests }}
allow_versions = true

[container-replicator]
{{- if .Values.container_replicator_debug }}
log_level = DEBUG
{{- end }}

[container-updater]

[container-auditor]

[container-sync]
interval = 300
container_time = 60
internal_client_conf_path = /etc/swift/internal-client-no-cache.conf

[container-sharder]
# Warning: auto-sharding is still under development and should not be used in
# production; do not set this option to true in a production cluster.
auto_shard = false
internal_client_conf_path = /etc/swift/internal-client-no-cache.conf
recon_candidates_limit = -1

[filter:healthcheck]
use = egg:swift#healthcheck
disable_path = /etc/swift/healthcheck/container.disabled


[filter:recon]
use = egg:swift#recon
recon_lock_path = /var/run/swift
