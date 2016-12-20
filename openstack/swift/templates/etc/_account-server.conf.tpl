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

[pipeline:main]
pipeline = healthcheck recon account-server

[app:account-server]
use = egg:swift#account

[account-replicator]

[account-auditor]

[account-reaper]
delay_reaping = 900


[filter:healthcheck]
use = egg:swift#healthcheck
disable_path = /etc/swift/healthcheck/account.disabled


[filter:recon]
use = egg:swift#recon
recon_lock_path = /var/run/swift
