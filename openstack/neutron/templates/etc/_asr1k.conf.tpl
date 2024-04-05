{{- define "asr1k_conf" -}}
{{- $config_agent := index . 1 -}}
{{- with index . 0 -}}

[asr1k]
wsma_adapter = {{$config_agent.wsma_adapter | default "asr1k_neutron_l3.models.wsma_adapters.SshWsmaAdapter"}}
preflights = VrfDefinition
clean_orphans = {{$config_agent.clean_orphans | default "True"}}
clean_orphan_interval = {{$config_agent.clean_orphan_interval | default 600}}
init_mode = {{$config_agent.init_mode | default "False"}}
trace_all_yang_calls = {{$config_agent.trace_all_yang_calls | default "False"}}
trace_yang_call_failures = {{$config_agent.trace_yang_call_failures | default "True"}}

[asr1k_l3]
fabric_asn = {{required "A valid .Values.asr.fabric_asn entry required!" .Values.asr.fabric_asn}}
max_requeue_attempts = 1
sync_active = {{$config_agent.l3_sync_active | default "True"}}
sync_chunk_size = {{$config_agent.l3_sync_chunk_size | default 10}}
sync_interval = {{$config_agent.l3_sync_interval | default 120}}
stateless_nat = {{$config_agent.stateless_nat | default "True"}}

# number of threads to spawn during router update, it must be < yang_connection_pool_size and if set higher
# the driver will reduce to = yang_connection_pool_size
threadpool_maxsize = {{$config_agent.asrl3_threadpool_pool_size | default 5}}
yang_connection_pool_size = {{$config_agent.netconf_yang_pool_size | default 10}}
legacy_connection_pool_size = {{$config_agent.netconf_legacy_pool_size | default 0}}

# snat mode, either "pool" or "interface"
snat_mode = {{ $config_agent.snat_mode | default "interface"}}
report_nat_stats = {{.Values.asr.report_nat_stats | default "False"}}

[asr1k_l2]
sync_active = {{$config_agent.l2_sync_active | default "True"}}
sync_chunk_size = {{$config_agent.l2_sync_chunk_size | default 10}}
sync_interval = {{$config_agent.l2_sync_interval | default 120}}
yang_connection_pool_size = {{$config_agent.netconf_yang_pool_size | default 5}}
legacy_connection_pool_size = 0

# These are Port-channelX
external_interface = 1
loopback_external_interface = 2
loopback_internal_interface = 3

{{ range $i, $hosting_device := $config_agent.hosting_devices}}
[asr1k_device:{{required "A valid $hosting_device required!" $hosting_device.name}}]
host = {{required "A valid $hosting_device required!" $hosting_device.ip}}
nc_timeout = {{$hosting_device.nc_timeout | default 20}}
use_bdvif = {{$hosting_device.use_bdvif | default "True"}}
{{end}}

[AGENT]
scheduling_disabled = {{ or ($config_agent.scheduling_disabled | default false) ($config_agent.decommissioning | default false) }}
{{- if $config_agent.availability_zone  }}
availability_zone = {{$config_agent.availability_zone}}
{{ end }}

{{- end -}}
{{- end }}
