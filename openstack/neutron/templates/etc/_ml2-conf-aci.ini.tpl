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
apic_username = {{required "A valid .Values.aci required!" .Values.aci.apic_user}}
apic_password = {{required "A valid .Values.aci required!" .Values.aci.apic_password}}
apic_use_ssl = True
apic_application_profile = {{required "A valid .Values.aci required!" .Values.aci.apic_application_profile}}

{{ if .Values.aci.aci_hostgroups }}
tenant_default_vrf = {{.Values.aci.tenant_default_vrf}}
flat_vlan_range={{.Values.aci.flat_vlan_range}}

# Set up host specific configuration needs to be one for each host that physically connects
# VMs or devices to the ACI fabric i.e. each hypervisor or L3 node.


{{- range $i, $aci_hostgroup := .Values.aci.aci_hostgroups.hostgroups }}
[aci-hostgroup:{{ $aci_hostgroup.name }}]
hosts = {{ $aci_hostgroup.hosts | join "," }}
bindings = {{ $aci_hostgroup.bindings | join "," }}
physical_domain = {{ default $.Values.aci.aci_hostgroups.physical_domains $aci_hostgroup.physical_domains | join "," }}
physical_network = {{ $aci_hostgroup.name }}
segment_type  = {{ $.Values.aci.aci_hostgroups.segment_type }}
segment_range = {{ default $.Values.aci.aci_hostgroups.segment_range $aci_hostgroup.segment_range }}
{{ end }}

{{- range $i, $fixed_binding := .Values.aci.fixed_bindings }}
[fixed-binding:{{ $fixed_binding.name }}]
description = {{ $fixed_binding.description }}
bindings = {{ $fixed_binding.bindings | join "," }}
physical_domain = {{ default $.Values.aci.aci_hostgroups.physical_domains $fixed_binding.physical_domains | join "," }}
segment_type  = {{ $.Values.aci.aci_hostgroups.segment_type }}
segment_id = {{ $fixed_binding.segment_id }}
{{ end }}

#AddressScope
{{- range $i, $address_scope := .Values.aci.address_scopes }}
{{ $address_scope.description }}
[address-scope:{{ $address_scope.name }}]
l3_outs = {{ $address_scope.l3_outs }}
contracts = {{ $address_scope.contracts }}
scope = {{ default "public" $address_scope.scope }}
vrf={{ $address_scope.vrf }}
{{ end }}

{{- else -}}
{{required "A valid .Values.aci required!" .Values.aci.bindings}}
{{- end -}}
