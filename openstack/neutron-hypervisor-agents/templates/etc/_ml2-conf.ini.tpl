[ml2]

# Changing type_drivers after bootstrap can lead to database inconsistencies
type_drivers = vlan,vxlan
tenant_network_types = vxlan,vlan

mechanism_drivers = {{required "A valid .Values.ml2_mechanismdrivers required!" .Values.ml2_mechanismdrivers}}

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
{{- if .Values.cc_fabric.enabled }}
    {{- range $i, $switchgroup := .Values.cc_fabric.driver_config.switchgroups -}}
        {{- if or (ne $i 0) ((($.Values.aci|default).aci_hostgroups|default).hostgroups|default) }},{{ end -}}
        {{- range $x, $range := $switchgroup.vlan_ranges | default $.Values.cc_fabric.driver_config.global_config.default_vlan_ranges -}}
            {{- if ne $x 0 }},{{ end -}}
            {{ $switchgroup.name}}:{{ $range }}
        {{- end -}}
    {{- end -}}
{{- end }}

[ml2_type_vxlan]
vni_ranges = 10000:20000

[ml2_f5]
supported_device_owners = network:f5listener,network:f5selfip,network:f5lbaasv2,network:f5snat,network:archer

[securitygroup]
{{- range $key, $value := .Values.securitygroup }}
{{ $key }} = {{ $value }}
{{- end }}

[agent]
polling_interval=5
prevent_arp_spoofing = False

[vxlan]
enable_vxlan = false
