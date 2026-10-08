{{/*
neutron.conf bodies for this library. Sensitive values ([DEFAULT] transport_url,
[linux_bridge] physical_interface_mappings, etc.) are injected via
OS_<SECTION>__<KEY> env vars from the consumer-supplied Secret, not written into
these files.

Layered so agents share the common sections:
  - neutron-agents.neutron-conf.default  → the [DEFAULT] section every agent needs
  - neutron-agents.neutron-conf.privsep  → the [privsep], privsep_* contexts, and
                                           [oslo_concurrency] sections every agent
                                           needs
  - neutron-agents.linuxbridge.neutron-conf → assembles default + linuxbridge
                                           sections + privsep for the linuxbridge
                                           agent.

A metadata/dhcp sibling would define neutron-agents.<agent>.neutron-conf the
same way: common default, its own sections, common privsep.

Inputs: .values is the consumer's library subtree for the agent (see values.yaml).
*/}}

{{- define "neutron-agents.neutron-conf.default" -}}
[DEFAULT]
core_plugin = ml2
debug = {{ .values.debug | default false }}
log_config_append = /etc/neutron/logging.conf
{{- with .values.host }}
host = {{ . }}
{{- end }}
{{- end -}}

{{- define "neutron-agents.neutron-conf.privsep" -}}
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

{{- define "neutron-agents.linuxbridge.neutron-conf" -}}
{{ include "neutron-agents.neutron-conf.default" . }}

[agent]
polling_interval = {{ dig "agent" "polling_interval" 2 .values }}

[linux_bridge]
# physical_interface_mappings comes from env OS_LINUX_BRIDGE__PHYSICAL_INTERFACE_MAPPINGS

[vxlan]
enable_vxlan = {{ dig "vxlan" "enable" false .values }}

[securitygroup]
firewall_driver = {{ dig "securitygroup" "firewall_driver" "iptables" .values }}

{{ include "neutron-agents.neutron-conf.privsep" . }}
{{- end -}}
