[uwsgi]
# This is running standalone
master = true
pyargv = --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2-conf.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-aci.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-manila.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-arista.ini --config-file /etc/neutron/plugins/ml2/ml2-conf-asr1k.ini {{- if .Values.bgp_vpn.enabled }} --config-file /etc/neutron/networking-bgpvpn.conf{{- end }}{{- if .Values.fwaas.enabled }} --config-file /etc/neutron/neutron-fwaas.ini{{- end }}
wsgi-file = /var/lib/openstack/bin/neutron-api
enable-threads = true
processes = {{.Values.api.processes}}
auto-procname = true
procname-prefix = neutron-api-
uid = neutron
gid = neutron
http-socket = :{{.Values.global.neutron_api_port_internal | default 9696}}

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

# Limits, Kill requests after 120 seconds
harakiri = 120
harakiri-verbose = true
post-buffering = 4096
backlog-status = true

{{ if gt (.Values.api.cheaper | int64) 0 -}}
# Automatic scaling of workers
cheaper = {{.Values.api.cheaper}}
cheaper-initial = {{.Values.api.cheaper}}
workers = {{.Values.api.processes}}
cheaper-step = 1
{{- end }}