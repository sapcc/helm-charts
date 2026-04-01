# dhcp_agent.ini
[DEFAULT]

debug = {{.Values.debug}}

dnsmasq_config_file = /etc/neutron/dnsmasq.conf
force_metadata=True
enable_isolated_metadata=True
metadata_proxy_socket = /run/metadata_proxy/metadata_proxy
dnsmasq_dns_servers = {{required "A valid .Values.dns_forwarders required!" .Values.dns_forwarders}}
num_sync_threads = {{.Values.agent.dhcp.num_sync_threads | default 4 }}
edns_client_fingerprint = {{.Values.agent.dhcp.edns_client_fingerprint | default "False" }}
netns_resolvconf = {{.Values.agent.dhcp.netns_resolvconf | default "False" }}
enable_router_advertisements = {{.Values.agent.dhcp.enable_router_advertisements | default "False" }}

rpc_response_timeout = {{ .Values.rpc_response_timeout | default .Values.global.rpc_response_timeout | default 50 }}
rpc_workers = {{ .Values.rpc_workers | default .Values.global.rpc_workers | default 5 }}
rpc_conn_pool_size = {{ .Values.rpc_conn_pool_size | default .Values.global.rpc_conn_pool_size | default 100 }}
