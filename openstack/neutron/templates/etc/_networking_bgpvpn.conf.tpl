[service_providers]
service_provider=BGPVPN:ASR1K:asr1k_neutron_l3.neutron.services.service_drivers.asr1k.ASR1KBGPVPNDriver:default

[bgpvpn]
{{- if or (.Values.bgp_vpn.import_target_auto_allocation) (.Values.bgp_vpn.export_target_auto_allocation) (.Values.bgp_vpn.route_target_auto_allocation) }}
region_asn = {{ required "A valid .Values.bgp_vpn.region_asn entry required!" .Values.bgp_vpn.region_asn }}
{{- end }}
target_id_range = {{ .Values.bgp_vpn.target_id_range | default "2000-4000" }}
import_target_auto_allocation = {{ .Values.bgp_vpn.import_target_auto_allocation | default "false" }}
export_target_auto_allocation = {{ .Values.bgp_vpn.export_target_auto_allocation | default "false" }}
route_target_auto_allocation = {{ .Values.bgp_vpn.route_target_auto_allocation | default "false" }}
