[ml2_aci]
sync_allocations =  {{.Values.aci.sync_allocations | default "True"}}
tenant_manager = hash_ring
tenant_ring_size = 60
tenant_items_managed = 1:60
tenant_prefix = {{required "A valid .Values.aci required!" .Values.aci.apic_tenant_name}}
support_remote_mac_clear = {{.Values.aci.support_remote_mac_clear | default "True"}}

polling_interval=60
sync_batch_size=15
prune_orphans=True

# Hostname:port list of APIC controllers
apic_hosts = {{required "A valid .Values.aci required!" .Values.aci.apic_hosts}}
apic_use_ssl = True
apic_application_profile = {{required "A valid .Values.aci required!" .Values.aci.apic_application_profile}}

{{ if .Values.aci.aci_hostgroups }}
tenant_default_vrf = {{.Values.aci.tenant_default_vrf}}
flat_vlan_range={{.Values.aci.flat_vlan_range}}
{{- if .Values.aci.ep_retention_policy_net_internal }}
ep_retention_policy_net_internal = {{ .Values.aci.ep_retention_policy_net_internal }}
{{- end }}
{{- if .Values.aci.ep_retention_policy_net_external }}
ep_retention_policy_net_external = {{ .Values.aci.ep_retention_policy_net_external }}
{{- end }}
{{- if .Values.aci.default_baremetal_pc_policy_group }}
default_baremetal_pc_policy_group = {{ .Values.aci.default_baremetal_pc_policy_group }}
{{ end }}
{{- if .Values.aci.baremetal_reserved_vlan_ids }}
baremetal_reserved_vlan_ids = {{ .Values.aci.baremetal_reserved_vlan_ids }}
{{- end }}
{{- if .Values.aci.az_checks_enabled }}
az_checks_enabled = {{ .Values.aci.az_checks_enabled }}
{{- end }}
{{- if .Values.aci.handle_all_l3_gateways }}
handle_all_l3_gateways = {{ .Values.aci.handle_all_l3_gateways }}
{{- end }}
{{- if .Values.aci.advertise_hostroutes }}
advertise_hostroutes = {{ .Values.aci.advertise_hostroutes }}
{{- end }}
{{- if .Values.aci.enable_nullroute_sync }}
enable_nullroute_sync = {{ .Values.aci.enable_nullroute_sync }}
{{- end }}
{{- if .Values.aci.enable_az_aware_subnet_routes_sync }}
enable_az_aware_subnet_routes_sync = {{ .Values.aci.enable_az_aware_subnet_routes_sync }}
{{- end }}
{{- if .Values.aci.sync_allocations_done_file_path }}
sync_allocations_done_file_path = {{ .Values.aci.sync_allocations_done_file_path }}
{{- end }}

{{- if .Values.aci.pc_policy_groups }}
{{ range $i, $pc_policy_group := .Values.aci.pc_policy_groups }}
[pc-policy-group:{{ $pc_policy_group.name }}]
lag_mode = {{ $pc_policy_group.lag_mode }}
link_level_policy = {{ $pc_policy_group.link_level_policy }}
cdp_policy = {{ $pc_policy_group.cdp_policy }}
lldp_policy = {{ $pc_policy_group.lldp_policy }}
lacp_policy = {{ $pc_policy_group.lacp_policy }}
monitoring_policy = {{ $pc_policy_group.monitoring_policy }}
mcp_policy = {{ $pc_policy_group.mcp_policy }}
l2_policy = {{ $pc_policy_group.l2_policy }}
{{ end -}}
{{- end }}

# Set up host specific configuration needs to be one for each host that physically connects
# VMs or devices to the ACI fabric i.e. each hypervisor or L3 node.


{{- range $i, $aci_hostgroup := .Values.aci.aci_hostgroups.hostgroups }}
[aci-hostgroup:{{ $aci_hostgroup.name }}]
hosts = {{ $aci_hostgroup.hosts | join "," }}
bindings = {{ $aci_hostgroup.bindings | join "," }}
physical_domain = {{ default $.Values.aci.aci_hostgroups.physical_domains $aci_hostgroup.physical_domains | join "," }}
physical_network = {{ default $aci_hostgroup.name $aci_hostgroup.physical_network }}
segment_type  = {{ $.Values.aci.aci_hostgroups.segment_type }}
segment_range = {{ default $.Values.aci.aci_hostgroups.segment_ranges $aci_hostgroup.segment_ranges | join "," }}
{{- if $aci_hostgroup.finalize_binding }}
finalize_binding = True
{{- end }}
{{- if $aci_hostgroup.fabric_transit }}
fabric_transit = True
{{- end }}
availability_zones = {{ default "" $aci_hostgroup.availability_zones | join "," }}
{{- if not (empty $aci_hostgroup.host_azs) }}
host_azs = {{ range $az, $hosts := $aci_hostgroup.host_azs -}}
        {{- range $n, $host := $hosts -}}
            {{ $host }}:{{ $az }}
            {{- if lt $n (sub (len $hosts) 1) -}},{{- end -}}
        {{- end -}}
    {{- end -}}
{{- end }}
{{ range $i, $subgroup := $aci_hostgroup.subgroups }}
[aci-hostgroup:{{ $subgroup.name }}]
hosts = {{ default $subgroup.name $subgroup.hosts | join "," }}
bindings = {{ $subgroup.bindings | join "," }}
segment_type  = {{ $.Values.aci.aci_hostgroups.segment_type }}
direct_mode = True
{{ if and (hasKey $subgroup "port_selectors") ( gt ($subgroup.port_selectors | len ) 0) -}}
port_selectors = {{ $subgroup.port_selectors | join "," }}
{{ if and (empty $subgroup.infra_pc_policy_group) (eq (len $subgroup.bindings) 1) -}}
infra_pc_policy_group = {{ (split "/" (index $subgroup.bindings 0))._3 }}
{{ else if and (hasKey $subgroup "port_selectors") (gt ($subgroup.port_selectors | len ) 0) -}}
infra_pc_policy_group = {{ required "If more than one direct binding is supplied and a port-selector is given the field infra_pc_policy_group is mandatory" $subgroup.infra_pc_policy_group }}
{{ end -}}
{{- if or $aci_hostgroup.baremetal_pc_policy_group $subgroup.baremetal_pc_policy_group -}}
baremetal_pc_policy_group = {{ default $aci_hostgroup.baremetal_pc_policy_group $subgroup.baremetal_pc_policy_group }}
{{ end -}}
{{ end -}}
parent_hostgroup = {{ $aci_hostgroup.name }}
{{ end -}}
{{ end -}}

{{- range $i, $fixed_binding := .Values.aci.fixed_bindings }}
[fixed-binding:{{ $fixed_binding.name }}]
description = {{ $fixed_binding.description }}
bindings = {{ $fixed_binding.bindings | join "," }}
physical_domain = {{ default $.Values.aci.aci_hostgroups.physical_domains $fixed_binding.physical_domains | join "," }}
segment_type  = {{ $.Values.aci.aci_hostgroups.segment_type }}
segment_id = {{ $fixed_binding.segment_id }}
{{ end }}

#AddressScope
{{ range $i, $address_scope := concat .Values.global_address_scopes .Values.local_address_scopes -}}
{{ $address_scope.description }}
[address-scope:{{ $address_scope.name }}]
l3_outs = {{ default (print "common/"  $address_scope.vrf) $address_scope.l3_outs }}
nullroute_l3_out = {{ default (print "common/"  ($address_scope.vrf | replace "cc-cloud" "cc-neutron" )) $address_scope.l3_outs }}
consumed_contracts = {{ default $address_scope.vrf (join "," $address_scope.consumed_contracts) }}
provided_contracts = {{ default $address_scope.vrf (join "," $address_scope.provided_contracts) }}
scope = {{ default "public" $address_scope.scope }}
vrf = {{ $address_scope.vrf }}
{{ end }}

{{- else -}}
{{required "A valid .Values.aci required!" .Values.aci.bindings}}
{{- end -}}
