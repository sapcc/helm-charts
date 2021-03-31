[ml2]

# Changing type_drivers after bootstrap can lead to database inconsistencies
type_drivers = vlan,vxlan
tenant_network_types = vxlan,vlan


#mechanism_drivers = aci,openvswitch,arista,asr,manila,f5ml2

mechanism_drivers = {{required "A valid .Values.ml2_mechanismdrivers required!" .Values.ml2_mechanismdrivers}}

# Designate configuration
extension_drivers = {{required "A valid .Values.dns_ml2_extension required!" .Values.dns_ml2_extension}}

path_mtu = {{.Values.global.default_mtu | default 9000}}

[ml2_type_vlan]
network_vlan_ranges = {{ range $i, $aci_hostgroup := .Values.aci.aci_hostgroups.hostgroups }}
    {{- $physical_network := default $aci_hostgroup.name $aci_hostgroup.physical_network -}}
    {{- $network_ranges := default $.Values.aci.aci_hostgroups.segment_ranges $aci_hostgroup.segment_ranges -}}

    {{- if ne $i 0 }},{{ end -}}
    {{- range $x, $range := $network_ranges -}}
        {{- if ne $x 0 }},{{ end -}}
        {{ $physical_network }}:{{ $range }}
    {{- end -}}
{{- end }}

[ml2_type_vxlan]
vni_ranges = 10000:20000


[securitygroup]
firewall_driver = iptables_hybrid
enable_security_group=True
enable_ipset=True

[agent]
polling_interval=5
prevent_arp_spoofing = False

[linux_bridge]
{{ if .Values.global.apods -}}
{{ $local := dict "first" true -}}
physical_interface_mappings = {{ range $k, $az := .Values.global.apods -}}
    {{- if not $local.first -}},{{- end -}}
    {{- $az -}}:{{required "A valid .Values.cp_network_interface required!" $.Values.cp_network_interface }}
    {{- $_ := set $local "first" false -}}
    {{- end }}{{- if .Values.cp_network_interface }},{{- $.Values.cp_physical_network -}}:{{required "A valid .Values.cp_network_interface required!" $.Values.cp_network_interface }}{{- end -}}
{{- else -}}
physical_interface_mappings = {{required "A valid .Values.cp_physical_network required!" .Values.cp_physical_network}}:{{required "A valid .Values.cp_network_interface required!" .Values.cp_network_interface}}
{{- end }}

[vxlan]
enable_vxlan = false

[ovs]
bridge_mappings = {{required "A valid .Values.cp_physical_network required!" .Values.cp_physical_network}}:br-{{required "A valid .Values.cp_network_interface required!" .Values.cp_network_interface}}
enable_tunneling=False




