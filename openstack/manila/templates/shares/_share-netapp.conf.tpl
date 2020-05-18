{{- define "share_netapp_conf" -}}
{{- $context := index . 0 -}}
{{- $enabled_share := index . 1 -}}
[DEFAULT]
storage_availability_zone = {{ $enabled_share.availability_zone | default $context.Values.default_availability_zone | default $context.Values.global.default_availability_zone }}
host = manila-share-netapp-{{$enabled_share.name}}
# Following opt is used for definition of share backends that should be enabled.
# Values are conf groupnames that contain per manila-share service opts.
enabled_share_backends = {{$enabled_share.name}}

{{- range $i, $share := $context.Values.global.netapp.filers }}

[{{$share.name}}]
share_backend_name={{$share.backend_name | default $share.vserver | default "netapp-multi"}}
replication_domain={{ $share.replication_domain | default $share.physical_network }}
share_driver=manila.share.drivers.netapp.common.NetAppDriver
{{- if $share.vserver }}
driver_handles_share_servers = false
netapp_vserver={{ $share.vserver }}
{{- else}}
driver_handles_share_servers = true
automatic_share_server_cleanup = true
# Unallocated share servers reclamation time interval (minutes).
unused_share_server_cleanup_interval = {{ $share.share_server_cleanup_interval | default 60 }}
netapp_vserver_name_template = ma_%s
{{- end }}

netapp_storage_family=ontap_cluster
netapp_server_hostname={{$share.host}}
netapp_server_port={{ $share.port | default 443 }}
netapp_transport_type={{ $share.protocol | default "https" }}
netapp_login={{$share.username}}
netapp_password={{$share.password}}
netapp_mtu={{$share.mtu | default 9000 }}
netapp_enabled_share_protocols={{$share.enabled_protocols | default "nfs3, nfs4.0" }}

netapp_root_volume_aggregate={{$share.root_volume_aggregate}}
netapp_aggregate_name_search_pattern={{$share.aggregate_search_pattern}}
netapp_reset_snapdir_visibility = hidden

netapp_lif_name_template = os_%(net_allocation_id)s
netapp_port_name_search_pattern = {{ $share.port_search_pattern  | default "(a0b)" }}

neutron_physical_net_name={{$share.physical_network}}
network_api_class=manila.network.neutron.neutron_network_plugin.NeutronBindNetworkPlugin
{{- if $share.debug }}
netapp_trace_flags=api,method
{{- end }}

# The percentage of backend capacity reserved. Default 0 (integer value)
reserved_share_percentage = {{ $share.reserved_share_percentage | default 33 }}

# Float representation of the over subscription ratio when thin
# provisioning is involved. Default ratio is 20.0, meaning provisioned
# capacity can be 20 times the total physical capacity. If the ratio
# is 10.5, it means provisioned capacity can be 10.5 times the total
# physical capacity. A ratio of 1.0 means provisioned capacity cannot
# exceed the total physical capacity. A ratio lower than 1.0 is
# invalid. (floating point value)
max_over_subscription_ratio = {{ $share.max_over_subscription_ratio | default $context.Values.max_over_subscription_ratio | default 3.0 }}

filter_function = {{ $share.filter_function | default "stats.provisioned_capacity_gb / stats.total_capacity_gb <= 0.7" }}

{{- end -}}
{{- end }}
