[DEFAULT]

# Make sure your swift-ring-builder arguments match the bind_ip and bind_port.
# You almost certainly do not want to listen just on loopback unless testing.
# However, you want to keep port 6202 if SElinux is enabled.
bind_ip = 0.0.0.0
bind_port = 6002

workers = 4
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

fallocate_reserve = {{ .Values.fallocate_reserve }}

[pipeline:main]
pipeline = healthcheck recon account-server

[app:account-server]
use = egg:swift#account

[account-replicator]
# If the account is reaped after deletion, means no conatiners belong to that
# account anymore, the account db is removed and the account may be recreated.
# Before the response to a deleted account will be 401 - Gone
# Default 7 days - we use 2 + 7 days day
reclaim_age = 777600

[account-auditor]

[account-reaper]
# Delay before the reaper will start cleaning out containers of the deleted
# account
# Default 0 - we use 2 days
delay_reaping = 172800

[filter:healthcheck]
use = egg:swift#healthcheck
disable_path = /etc/swift/healthcheck/account.disabled

[filter:recon]
use = egg:swift#recon
recon_lock_path = /var/run/swift
