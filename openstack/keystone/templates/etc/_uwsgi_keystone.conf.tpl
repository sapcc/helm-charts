[uwsgi]
# This is running standalone
master = true
wsgi-file = /var/lib/openstack/bin/keystone-wsgi-public
enable-threads = true
processes = 8
auto-procname = true
procname-prefix = keystone-api-
uid = keystone
gid = keystone
http-socket = :5000

# Connection tuning
vacuum = true
lazy-apps = true
need-app = true
thunder-lock = true
buffer-size = 114688
add-header = Connection: close
single-interpreter = true
worker-reload-mercy = 90

# Set die-on-term & exit-on-reload so that uwsgi shuts down
exit-on-reload = false
die-on-term = true
hook-master-start = unix_signal:15 gracefully_kill_them_all
py-call-osafterfork = true

# logging and metrics
log-x-forwarded-for = true
log-date = %%Y-%%m-%%d %%H:%%M:%%S,000
log-format-strftime = true
log-format = %(ftime) %(pid) INFO uWSGI [%(request_id) g%(global_request_id) %(user_id) %(project) %(domain) %(user_domain) %(project_domain)] %(addr) "%(method) %(uri) %(proto)" status: %(status) len: %(size) time: %(secs) agent: %(uagent)
plugin = dogstatsd
stats-push = dogstatsd:127.0.0.1:9125
dogstatsd-all-gauges = true
memory-report = true

# Limits, Kill requests after 120 seconds
harakiri = 120
harakiri-verbose = true
post-buffering = 4096
backlog-status = true