bind = '0.0.0.0:{{.Values.global.neutron_api_port_internal | default 9696}}'
backlog = 2048
preload_app = True
workers = 25
worker_class = 'eventlet'
worker_connections = 1000
loglevel = 'info'
timeout = 120
keepalive = 0
reuse_port = True
daemon = False
accesslog = '-'
wsgi_app = 'neutron.server:get_application'
raw_env = ["OS_NEUTRON_CONFIG_FILES=/etc/neutron/neutron.conf;/etc/neutron/plugins/ml2/ml2-conf.ini;/etc/neutron/plugins/ml2/ml2-conf-aci.ini;/etc/neutron/plugins/ml2/ml2-conf-manila.ini;/etc/neutron/plugins/ml2/ml2-conf-arista.ini;/etc/neutron/plugins/ml2/ml2-conf-asr1k.ini{{- if .Values.bgp_vpn.enabled }};/etc/neutron/networking-bgpvpn.conf{{- end }}{{- if .Values.fwaas.enabled }};/etc/neutron/neutron-fwaas.ini{{- end }}", "OS_NEUTRON_CONFIG_DIR=/etc/neutron"]
statsd_host = '127.0.0.1:9125'
user = 'neutron'
group = 'neutron'