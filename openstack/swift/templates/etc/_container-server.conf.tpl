[DEFAULT]

# Make sure your swift-ring-builder arguments match the bind_ip and bind_port.
# You almost certainly do not want to listen just on loopback unless testing.
# However, you want to keep port 6201 if SElinux is enabled.
bind_ip = 0.0.0.0
bind_port = 6001

workers = 8
max_clients = 1024
backlog = 4096

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
{{- if .Values.sentry.enabled }}
log_custom_handlers = swift_sentry.sentry_logger
{{- end }}

# This option is broken on py3.
# Reference: https://bugs.launchpad.net/swift/+bug/1872553
# fallocate_reserve = {{ .Values.fallocate_reserve }}

[pipeline:main]
pipeline = healthcheck recon container-server

[app:container-server]
use = egg:swift#container
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
internal_client_conf_path = /etc/swift/container-sync-internal-client.conf


[filter:healthcheck]
use = egg:swift#healthcheck
disable_path = /etc/swift/healthcheck/container.disabled


[filter:recon]
use = egg:swift#recon
recon_lock_path = /var/run/swift
