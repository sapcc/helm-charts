{{- define "share_netapp_conf" -}}
{{- $context := index . 0 -}}
{{- $enabled_share := index . 1 -}}
[DEFAULT]
storage_availability_zone = {{ $enabled_share.availability_zone | default $context.Values.default_availability_zone | default $context.Values.global.default_availability_zone }}
host = manila-share-netapp-{{$enabled_share.name}}
# Following opt is used for definition of share backends that should be enabled.
# Values are conf groupnames that contain per manila-share service opts.
enabled_share_backends = {{$enabled_share.name}}

[coordination]
# overrides configuration from manila.conf
backend_url = file://$state_path

{{- range $i, $share := $context.Values.global.netapp.filers }}
{{- $share_backend := $share.backend_name | default $share.vserver | default "netapp-multi"}}

[{{$share.name}}]
share_backend_name={{ $share_backend }}
replication_domain={{ $share.replication_domain | default $share_backend }}
share_driver=manila.share.drivers.netapp.common.NetAppDriver
{{- if $share.vserver }}
driver_handles_share_servers = false
netapp_vserver={{ $share.vserver }}
{{- else}}
driver_handles_share_servers = true
automatic_share_server_cleanup = true
# Unallocated share servers reclamation time interval (minutes).
# Should match netapp_delete_retention_hours, otherwise vservers may be cleaned up too early
unused_share_server_cleanup_interval = {{ $share.share_server_cleanup_interval | default 720 }}
netapp_vserver_name_template = {{ $share.netapp_vserver_name_template | default $context.Values.netapp_vserver_name_template | default "ma_%s" }}
{{- end }}

netapp_storage_family=ontap_cluster
netapp_server_hostname={{$share.host}}
netapp_server_port={{ $share.port | default 443 }}
netapp_transport_type={{ $share.protocol | default "https" }}
netapp_mtu={{$share.mtu | default 9000 }}
netapp_enabled_share_protocols={{$share.enabled_protocols | default "nfs3, nfs4.1" }}

netapp_root_volume_aggregate={{$share.root_volume_aggregate}}
netapp_aggregate_name_search_pattern={{$share.aggregate_search_pattern}}
netapp_reset_snapdir_visibility = hidden

netapp_volume_name_template = {{ $share.netapp_volume_name_template | default $context.Values.netapp_volume_name_template | default "share_%(share_id)s" }}
netapp_lif_name_template = os_%(net_allocation_id)s
netapp_port_name_search_pattern = {{ $share.port_search_pattern  | default "(a0b)" }}

neutron_physical_net_name={{$share.physical_network}}
{{ if hasKey $share "binding_host" }}
neutron_host_id={{$share.binding_host}}
{{- end }}
network_api_class=manila.network.neutron.neutron_network_plugin.NeutronBindNetworkPlugin
{{- if $share.debug }}
netapp_trace_flags=api,method
{{- end }}

# Enable the net_capacity provisioning
netapp_volume_provision_net_capacity = True
netapp_volume_snapshot_reserve_percent = {{ $share.netapp_volume_snapshot_reserve_percent | default $context.Values.netapp_volume_snapshot_reserve_percent | default 50 }}

# Enable logical space reporting
netapp_enable_logical_space_reporting = False

# Set the last transfer size limit to 1 GB (1024 * 1024 KB). We need to find a sweet
# spot for this value. Our goal is to alert customers about large data copies occurring,
# allowing them to take preventive actions before replica promotion. While 1GB is a
# relatively high value, it helps to avoid too many 'out-of-sync' replicas. We could
# also consider lowering this value to 512MB, but we need to be careful about the
# impact.
netapp_snapmirror_last_transfer_size_limit = 1048576

# Set asynchronous SnapMirror schedule to one hour, and configure the waiting time for
# snapmirror to complete on replica promote to be double of this value, alligning with
# our RPO (Recovery Point Objective) of 2 hours.
netapp_snapmirror_schedule = "hourly"
netapp_snapmirror_quiesce_timeout = 7200

# state, that will be reported as pool property. Valid values are `in_build`, `live`, `in_decom` and `replacing_decom`
netapp_hardware_state = {{ $share.hardware_state | default "live" }}

# The percentage of backend capacity reserved. Default 0 (integer value)

{{- if eq 100 (int $share.reserved_share_percentage)}}
reserved_share_percentage = 100
{{- else }}
reserved_share_percentage = {{ $share.reserved_share_percentage | default 30 }}
{{- end }}

{{- if eq 100 (int $share.reserved_share_extend_percentage)}}
reserved_share_extend_percentage = 100
{{- else }}
reserved_share_extend_percentage = {{ $share.reserved_share_extend_percentage | default 25 }}
{{- end }}

{{- if eq 100 (int $share.reserved_share_from_snapshot_percentage)}}
reserved_share_from_snapshot_percentage = 100
{{- else }}
reserved_share_from_snapshot_percentage = {{ $share.reserved_share_from_snapshot_percentage | default 25 }}
{{- end }}

# Time to kepp deleted volumes in recovery queue until space is reclaimed
netapp_delete_retention_hours = {{ $context.Values.delete_retention_hours | default 12 }}

# Float representation of the over subscription ratio when thin
# provisioning is involved. Default ratio is 20.0, meaning provisioned
# capacity can be 20 times the total physical capacity. If the ratio
# is 10.5, it means provisioned capacity can be 10.5 times the total
# physical capacity. A ratio of 1.0 means provisioned capacity cannot
# exceed the total physical capacity. A ratio lower than 1.0 is
# invalid. (floating point value)
max_over_subscription_ratio = {{ $share.max_over_subscription_ratio | default $context.Values.max_over_subscription_ratio | default 3.0 }}

# maximum number of volumes created in a SVM
max_shares_per_share_server = {{ $share.max_shares_per_share_server | default $context.Values.max_shares_per_share_server | default 50 }}
# maximum sum of gigabytes a SVM can have considering all its share instances and snapshots
max_share_server_size  = {{ $share.max_share_server_size | default $context.Values.max_share_server_size | default 10240 }}

filter_function = {{ $share.filter_function | default "stats.provisioned_capacity_gb / stats.total_capacity_gb <= 0.7" }}
goodness_function = {{ $share.goodness_function | default "((share.share_proto == 'CIFS') and (capabilities.channel_binding_support)) ? 100 : 50" }}

{{- end -}}
{{- end }}
