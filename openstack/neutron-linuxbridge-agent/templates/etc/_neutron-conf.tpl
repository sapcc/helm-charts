{{/*
neutron.conf body for the linuxbridge agent. Sensitive values
([DEFAULT] transport_url, etc.) are injected via OS_<SECTION>__<KEY>
env vars from the consumer-supplied Secret, not written into this file.

Inputs: .values is the consumer's library subtree (see values.yaml).
*/}}
{{- define "neutron-linuxbridge-agent.neutron-conf" -}}
[DEFAULT]
core_plugin = ml2
debug = {{ .values.debug | default false }}
log_config_append = /etc/neutron/logging.conf
{{- with .values.host }}
host = {{ . }}
{{- end }}

[agent]
polling_interval = {{ dig "agent" "polling_interval" 2 .values }}

[linux_bridge]
# physical_interface_mappings comes from env OS_LINUX_BRIDGE__PHYSICAL_INTERFACE_MAPPINGS

[vxlan]
enable_vxlan = {{ dig "vxlan" "enable" false .values }}

[securitygroup]
firewall_driver = {{ dig "securitygroup" "firewall_driver" "iptables" .values }}

[privsep]
thread_pool_size = {{ dig "privsep" "thread_pool_size" 3 .values }}
helper_command = {{ dig "privsep" "helper_command" "privsep-helper --config-file /etc/neutron/neutron.conf" .values }}

# All neutron privsep contexts use the same in-container helper invocation,
# avoiding sudo (which isn't usable in the bare-minimum container).
{{- $helper := dig "privsep" "helper_command" "privsep-helper --config-file /etc/neutron/neutron.conf" .values }}
{{- range list "privsep_dhcp_release" "privsep_ovs_vsctl" "privsep_namespace" "privsep_conntrack" "privsep_link" }}

[{{ . }}]
helper_command = {{ $helper }}
{{- end }}

[oslo_concurrency]
lock_path = /tmp
{{- end -}}
