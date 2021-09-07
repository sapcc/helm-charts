[uwsgi]
# This is running standalone
master = true
pyargv = --config-file /etc/glance/glance.conf
wsgi-file = /var/lib/openstack/bin/glance-wsgi-api
enable-threads = true
processes = {{.Values.api.processes}}
auto-procname = true
procname-prefix = glance-api-
uid = glance
gid = glance
http-socket = :{{.Values.global.glance_api_port_internal | default 9292}}
socket-timeout = 10
http-auto-chunked = true
http-chunked-input = true
http-raw-body = true

# Connection tuning
vacuum = true
lazy-apps = true
need-app = true
thunder-lock = true
buffer-size = 65535
add-header = Connection: close
single-interpreter = true
worker-reload-mercy = 90

# Set die-on-term & exit-on-reload so that uwsgi shuts down
exit-on-reload = false
die-on-term = true
hook-master-start = unix_signal:15 gracefully_kill_them_all

# logging and metrics
log-format = [pid: %(pid)] %(addr) {%(vars) vars in %(pktsize) bytes} [%(ctime)] %(method) %(uri) => generated %(rsize) bytes in %(msecs) msecs (%(proto) %(status)) %(headers) headers in %(hsize) bytes
plugin = dogstatsd
stats-push = dogstatsd:127.0.0.1:9125
dogstatsd-all-gauges = true
memory-report = true

{{ if gt (.Values.api.cheaper | int64) 0 -}}
# Automatic scaling of workers
cheaper = {{.Values.api.cheaper}}
cheaper-initial = {{.Values.api.cheaper}}
workers = {{.Values.api.processes}}
cheaper-step = 1
{{- end }}