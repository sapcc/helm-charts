[ml2]
# this is a hack to enable ovn mechanism driver only in the neutron-server and db-sync.
# neutron-rpc-server has issues with RPC when OVN is enabled but doesn't need it at all.
mechanism_drivers = {{required "A valid .Values.ml2_mechanismdrivers required!" .Values.ml2_mechanismdrivers}},ovn

[ovn]
{{- $ovsdb_nb := index (index .Values "ovsdb-nb") }}
{{- $ovsdb_sb := index (index .Values "ovsdb-sb") }}
# we always use TCP, encryption is recommended to be done by reverse proxy
{{- $ovsdb_nb_addr := printf "%s.%s.svc.kubernetes.%s.%s" ( include "ovsdb.fullname" . )
  .Release.Namespace
  .Values.global.region
  .Values.global.tld
}}
ovn_nb_connection = tcp:{{ required "ovsdb-nb.EXTERNAL_IP required!" $ovsdb_nb.EXTERNAL_IP }}:{{ $ovsdb_nb.DB_PORT }}
ovn_sb_connection = tcp:{{ required "ovsdb-sb.EXTERNAL_IP required!" $ovsdb_sb.EXTERNAL_IP }}:{{ $ovsdb_sb.DB_PORT }}

neutron_sync_mode = {{ .Values.ovn.neutron_sync_mode | default "off" }}
ovsdb_log_level = {{ .Values.ovn.logLevel | default "INFO" }}
ovn_metadata_enabled = {{ .Values.ovn.metadata_enabled | default "false" }}
disable_ovn_dhcp_for_baremetal_ports = {{ .Values.ovn.disable_ovn_dhcp_for_baremetal_ports | default "true" }}
{{ with .Values.ovn.dns_servers }}dns_servers = {{ . | join "," }}{{ end }}
{{ with .Values.ovn.ovn_dhcp4_global_options }}ovn_dhcp4_global_options = {{ . }}{{ end }}
{{ with .Values.ovn.ovn_dhcp6_global_options }}ovn_dhcp6_global_options = {{ . }}{{ end }}
{{ with .Values.ovn.dhcp_default_lease_time }}dhcp_default_lease_time = {{ . }}{{ end }}
mac_binding_age_threshold = 86400
