[asr1k]

monitor = asr1k_neutron_l3.common.prometheus_monitor.PrometheusMonitor
wsma_adapter={{.Values.asr.wsma_adapter | default "asr1k_neutron_l3.models.wsma_adapters.SshWsmaAdapter"}}

[asr1k_l3]

fabric_asn = {{.Values.asr.fabric_asn}}
max_requeue_attempts=1
sync_active = {{.Values.asr.l3_sync_active | default "True"}}
sync_chunk_size = {{.Values.asr.l3_sync_chunk_size | default 10}}
sync_interval = {{.Values.asr.l3_sync_interval | default 120}}
# number of threads to spawn during router update, it must be < yang_connection_pool_size and if set higher
# the driver will reduce to = yang_connection_pool_size
threadpool_maxsize={{.Values.asrl3_threadpool_pool_size | default 5}}
yang_connection_pool_size={{.Values.asr.netconf_yang_pool_size | default 5}}
legacy_connection_pool_size={{.Values.asr.netconf_legacy_pool_size | default 5}}


[asr1k_l2]
sync_active = {{.Values.asr.l2_sync_active | default "True"}}
sync_chunk_size = {{.Values.asr.l2_sync_chunk_size | default 10}}
sync_interval = {{.Values.asr.l2_sync_interval | default 120}}
yang_connection_pool_size={{.Values.asr.netconf_yang_pool_size | default 5}}
legacy_connection_pool_size=0

# These are Port-channelX
external_interface = 1
loopback_external_interface = 2
loopback_internal_interface = 3


{{ range $i, $hosting_device := .Values.asr.hosting_devices}}
[asr1k_device:{{$hosting_device.name}}]
host = {{$hosting_device.ip}}
user_name = {{$hosting_device.user_name}}
password = {{$hosting_device.password}}
nc_timeout = {{$hosting_device.nc_timeout | default 20}}
{{end}}



[asr1k-address-scopes]
{{ range $i, $address_scope := .Values.asr.address_scopes}}
{{$address_scope.name}}={{$address_scope.rd}}
{{end}}