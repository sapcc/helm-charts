{{- define "nova_compute_kvm_conf" }}
{{- $hypervisor := index . 1 }}
{{- with index . 0 }}
[DEFAULT]
# Needs to be same on hypervisor and scheduler
scheduler_instance_sync_interval = {{ .Values.scheduler.scheduler_instance_sync_interval }}
{{- range $k, $v := $hypervisor.default }}
{{ $k }} = {{ $v }}
{{- end }}

[filter_scheduler]
# Needs to be same on hypervisor and scheduler
track_instance_changes = {{ .Values.scheduler.track_instance_changes }}

[libvirt]
connection_uri = "qemu+tcp://127.0.0.1/system"
iscsi_use_multipath=True
#inject_key=True
#inject_password = True
#live_migration_downtime = 500
#live_migration_downtime_steps = 10
#live_migration_downtime_delay = 75
#live_migration_flag = VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER, VIR_MIGRATE_LIVE, VIR_MIGRATE_TUNNELLED

{{- end }}
{{- end }}
