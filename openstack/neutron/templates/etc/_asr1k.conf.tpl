[asr1k]

monitor = asr1k_neutron_l3.common.prometheus_monitor.PrometheusMonitor

[asr1k_l3]

fabric_asn = {{.Values.asr.fabric_asn}}
max_requeue_attempts=10



[asr1k_l2]
sync_active = True
sync_chunk_size = 30
sync_interval = 60

# These are Port-channelX
external_interface = 1
loopback_external_interface = 2
loopback_internal_interface = 3


{{ range $i, $hosting_device := .Values.asr.hosting_devices}}
[asr1k_device:{{$hosting_device.name}}]
host = {{$hosting_device.ip}}
user_name = {{$.Values.asr.credential_1_user_name}}
password = {{$.Values.asr.credential_1_password}}
{{end}}



[asr1k-address-scopes]
{{ range $i, $address_scope := .Values.asr.address_scopes}}
{{$address_scope.name}}={{$address_scope.rd}}
{{end}}