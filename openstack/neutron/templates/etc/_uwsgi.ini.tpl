[uwsgi]
# This is running standalone
master = true
pyargv = --config-file /etc/neutron/neutron.conf --config-dir /etc/neutron/secrets --config-file /etc/neutron/plugins/ml2/ml2-conf.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-aci.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-manila.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-arista.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-asr1k.ini --config-file /etc/neutron/plugins/asr1k-global.ini {{- if .Values.bgp_vpn.enabled }} --config-file /etc/neutron/networking-bgpvpn.conf{{- end }}{{- if .Values.interconnection.enabled }} --config-file /etc/neutron/networking-interconnection.conf{{- end }}{{- if .Values.fwaas.enabled }} --config-file /etc/neutron/neutron-fwaas.ini{{- end }}{{- if .Values.cc_fabric.enabled }} --config-file /etc/neutron/plugins/ml2/ml2_conf_cc-fabric.ini {{- end }}
wsgi-file = /var/lib/openstack/bin/neutron-api
enable-threads = true
processes = {{.Values.api.processes}}
auto-procname = true
procname-prefix = neutron-api-
uid = neutron
gid = neutron
http = :{{.Values.global.neutron_api_port_internal | default 9696}}
plugins-dir = /var/lib/openstack/lib
need-plugins = dogstatsd,shortmsecs

# Connection tuning
vacuum = true
lazy-apps = true
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
py-call-osafterfork = true

# logging and metrics, sadly no sub-seconds
log-x-forwarded-for = true
log-date = %%Y-%%m-%%d %%H:%%M:%%S
log-format-strftime = true
log-format = %(ftime),%(shortmsecs) %(pid) INFO uWSGI [%(request_id) g%(global_request_id) %(user_id) %(project) %(domain) %(user_domain) %(project_domain)] %(addr) "%(method) %(uri) %(proto)" status: %(status) len: %(size) time: %(secs) agent: %(uagent)
plugin = dogstatsd
stats-push = dogstatsd:127.0.0.1:9125
dogstatsd-all-gauges = true
memory-report = true

# HTTP-Socket Timeout
http-timeout = 120

# Limits, Kill requests after 120 seconds
harakiri = 120
harakiri-verbose = true
{{ if .Values.api.uwsgi_enable_harakiri_graceful_signal -}}
# Send SIGWINCH signal to trigger guru_meditation report creation
harakiri-graceful-signal = 28
harakiri-graceful-timeout = 5
{{ end -}}
post-buffering = 4096
backlog-status = true
py-tracebacker = /var/lib/neutron/uwsgi_pytracebacker.

{{ if gt (.Values.api.cheaper | int64) 0 -}}
# Automatic scaling of workers
cheaper = {{.Values.api.cheaper}}
cheaper-initial = {{.Values.api.cheaper}}
workers = {{.Values.api.processes}}
cheaper-step = 1
{{- end }}
