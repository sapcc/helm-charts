{{- $hypervisor := merge .Values.defaults.hypervisor.kvm .Values.defaults.hypervisor.common -}}
[DEFAULT]
# Needs to be same on hypervisor and scheduler
scheduler_instance_sync_interval = {{ .Values.scheduler.scheduler_instance_sync_interval }}
{{- range $k, $v := $hypervisor.default }}
{{ $k }} = {{ $v }}
{{- end }}

[filter_scheduler]
# Needs to be same on hypervisor and scheduler
track_instance_changes = {{ .Values.scheduler.track_instance_changes }}

[keystone_authtoken]
valid_interfaces = public

[service_user]
auth_interface = public

[placement]
valid_interfaces = public

[barbican]
backend = barbican

[cinder]
valid_interfaces = public

[neutron]
valid_interfaces = public

[glance]
valid_interfaces = public

{{- if $hypervisor.config_file }}
{{"\n"}}
{{- include "util.helpers.valuesToIni" $hypervisor.config_file }}
{{- end }}

{{- tuple . "cell1" $hypervisor.vnc | include "console-novnc.conf" }}

{{- tuple . "cell1" $hypervisor.serial | include "console-serial.conf" }}
