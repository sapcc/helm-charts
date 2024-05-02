{{- define "kvm_configmap" }}
{{- $hypervisor := merge .Values.defaults.hypervisor.kvm .Values.defaults.hypervisor.common }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: nova-compute-kvm
  labels:
    system: openstack
    type: configuration
    component: nova
data:
  nova-compute.conf: |
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
    {{- include "util.helpers.valuesToIni" $hypervisor.config_file | indent 4 }}
    {{- end }}

  libvirtd.conf: |
    listen_tcp = 1
    listen_tls = 0
    mdns_adv = 0
    auth_tcp = "none"
    ca_file = ""
    log_level = 3
    log_outputs = "3:stderr"
    listen_addr = "127.0.0.1"
{{- end }}
