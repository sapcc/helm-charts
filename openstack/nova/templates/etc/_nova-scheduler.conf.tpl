[DEFAULT]
# Scheduling
scheduler_host_manager = {{ if .Values.global.hypervisors_ironic }}ironic_host_manager{{ else }}host_manager{{ end }}
scheduler_driver = {{ .Values.scheduler.driver }}

[scheduler]
discover_hosts_in_cells_interval = 60
workers = {{ .Values.scheduler.workers | default 1 }}
driver_task_period = {{ .Values.scheduler.driver_task_period | default 60 }}

[filter_scheduler]
available_filters = {{ .Values.scheduler.available_filters | default "nova.scheduler.filters.all_filters" }}
enabled_filters = {{ .Values.scheduler.default_filters }}
track_instance_changes = {{ .Values.scheduler.scheduler_tracks_instance_changes }}
bigvm_host_size_filter_uses_flavor_extra_specs = true
bigvm_host_size_filter_host_fractions = full:1,half:0.5,two_thirds:0.71
vm_size_threshold_vm_size_mb = {{ .Values.scheduler.vm_size_threshold_vm_size_mb }}
vm_size_threshold_hv_size_mb = {{ .Values.scheduler.vm_size_threshold_hv_size_mb }}

cpu_weight_multiplier = {{ .Values.scheduler.cpu_weight_multiplier }}
ram_weight_multiplier = {{ .Values.scheduler.ram_weight_multiplier }}
disk_weight_multiplier =  {{ .Values.scheduler.disk_weight_multiplier }}
io_ops_weight_multiplier = {{ .Values.scheduler.io_ops_weight_multiplier }}
soft_affinity_weight_multiplier = {{ .Values.scheduler.soft_affinity_weight_multiplier }}
prefer_same_host_resize_weight_multiplier = {{ .Values.scheduler.prefer_same_host_resize_weight_multiplier }}
