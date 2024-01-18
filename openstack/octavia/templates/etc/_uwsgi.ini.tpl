[uwsgi]
# This is running standalone
master = true
pyargv = --config-file /etc/octavia/octavia.conf
wsgi-file = /var/lib/openstack/bin/octavia-wsgi
enable-threads = true
processes = 1
threads = 100
auto-procname = true
procname-prefix = octavia-api-
uid = octavia
gid = octavia
http = :{{.Values.api_port_internal}}
plugins-dir = /var/lib/openstack/lib
need-plugins = dogstatsd,shortmsecs

# Connection tuning
vacuum = true
need-app = true
thunder-lock = true
buffer-size = 65535
listen = 4096
add-header = Connection: close
single-interpreter = true
worker-reload-mercy = 90

# Set die-on-term & exit-on-reload so that uwsgi shuts down
exit-on-reload = false
die-on-term = true
hook-master-start = unix_signal:15 gracefully_kill_them_all

# logging and metrics, sadly no sub-seconds
log-x-forwarded-for = true
log-date = %%Y-%%m-%%d %%H:%%M:%%S
log-format-strftime = true
log-format = %(ftime),%(shortmsecs) %(pid) INFO uWSGI [%(request_id) g%(global_request_id) %(user_id) %(project) %(domain) %(user_domain) %(project_domain)] %(addr) "%(method) %(uri) %(proto)" status: %(status) len: %(size) time: %(secs) agent: %(uagent)
plugin = dogstatsd
stats-push = dogstatsd:127.0.0.1:9125
dogstatsd-all-gauges = true
memory-report = true

# Limits, Kill requests after 120 seconds
harakiri = 120
harakiri-verbose = true
post-buffering = 4096
backlog-status = true
