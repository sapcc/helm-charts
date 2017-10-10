### Networking-DVS Alerts ###

ALERT OpenstackDVSPolling
  IF min(rate(openstack_networking_dvs_plugins_ml2_drivers_mech_dvs_agent_dvs_agent_process_ports_timer_count[5m])) by (kubernetes_pod_name) *60 < 1
  FOR 5m
  LABELS {
    service = "nova",
    severity = "info",
    tier = "openstack",
    dashboard = "neutron-dvs-agent",
    meta = "{{ $labels.kubernetes_pod_name }} below 1min"
  }
  ANNOTATIONS {
    summary = "Polling iterations fall below 1 per minute",
    description = "Polling iterations of DVS Agent {{ $labels.kubernetes_pod_name }} is below 1 per minute.",
  }

ALERT OpenstackDVSSecGroup
  IF max(openstack_networking_dvs_security_group_updates_timer{quantile="0.99"}) by (kubernetes_pod_name) > 60
  FOR 5m
  LABELS {
    service = "nova",
    severity = "info",
    tier = "openstack",
    dashboard = "neutron-dvs-agent",
    meta = "{{ $labels.kubernetes_pod_name }} below 1min"
  }
  ANNOTATIONS {
    summary = "security group latency goes over 1 minute",
    description = "Security Group latency of DVS Agent {{ $labels.kubernetes_pod_name }} is over 1 minute.",
  }

### Nova Metrics ###

ALERT OpenstackNovaMaxDiskUsagePerc
  IF 1.0 - max(openstack_compute_nodes_free_disk_gb_gauge{host!~".*ironic.*"}/openstack_compute_nodes_local_gb_gauge) by (availability_zone) > .90
  FOR 8h
  LABELS {
    service = "nova",
    severity = "critical",
    context= "diskspace",
    tier = "openstack",
    dashboard = "nova-hypervisor",
    meta = "{{ $labels.availability_zone }} DiskUsage above 90%"
  }
  ANNOTATIONS {
    summary = "Nova Maximum Disk Usage percentage metric",
    description = "Nova Maximum Disk Usage is above 90%",
  }

ALERT OpenstackNovaMaxRAMUsagePerc
  IF 1.0 - min(openstack_compute_nodes_free_ram_mb_gauge{host!~".*ironic.*"}/openstack_compute_nodes_memory_mb_gauge) by (availability_zone) > .95
  FOR 8h
  LABELS {
    service = "nova",
    severity = "warning",
    context= "diskspace",
    tier = "openstack",
    dashboard = "nova-hypervisor",
    meta = "{{ $labels.availability_zone }} RAMUsage above 95%"
  }
  ANNOTATIONS {
    summary = "Nova Maximum RAM Usage percentage metric",
    description = "Nova Maximum RAM Usage is above 95%.",
  }

ALERT OpenstackNovaInstanceStuckBuilding
  IF sum(openstack_compute_stuck_instances_count_gauge{vm_state="building",host!='nova-compute-ironic'}) by (host) > 0
  FOR 5m
  LABELS {
    service = "nova",
    severity = "info",
    tier = "openstack",
    dashboard = "nova-hypervisor",
    meta = "{{`{{ $value }}`}} instances",
    {{ if .Values.ops_docu_url -}}
      playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/nova/instance_error_on_create.html",
    {{- end }}
  }
  ANNOTATIONS {
    summary = "Openstack Nova Instance Stuck in Building state metric",
    description = "Nova Instance Stuck in Building state over 15mins in {{ $labels.host }}",
  }

ALERT OpenstackNovaInstanceStuckDeleting
  IF sum(openstack_compute_stuck_instances_count_gauge{vm_state="deleting"}) by (host) > 0
  FOR 5m
  LABELS {
    service = "nova",
    severity = "info",
    tier = "openstack",
    dashboard = "nova-hypervisor",
    meta = "{{`{{ $value }}`}}instances",
    {{ if .Values.ops_docu_url -}}
      playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/nova/delete_stuck_instance.html/#Delete",
    {{- end }}
  }
  ANNOTATIONS {
    summary = "Openstack Nova Instance Stuck in Deleting state metric",
    description = "Nova Instance Stuck in Deleting state over 15mins in {{ $labels.host }}",
  }

ALERT OpenstackNovaInstanceStuckStopping
  IF sum(openstack_compute_stuck_instances_count_gauge{vm_state="stopping"}) by (host) > 0
  FOR 5m
  LABELS {
    service = "nova",
    severity = "info",
    tier = "openstack",
    dashboard = "nova-hypervisor",
    meta = "{{ $value }} instances"
  }
  ANNOTATIONS {
    summary = "Openstack Nova Instance Stuck in Stopping state metric",
    description = "Nova Instance Stuck in Stopping state over 15mins in {{ $labels.host }}",
  }

ALERT OpenstackNovaInstanceStuckStarting
  IF sum(openstack_compute_stuck_instances_count_gauge{vm_state="starting"}) by (host) > 0
  FOR 5m
  LABELS {
    service = "nova",
    severity = "info",
    tier = "openstack",
    dashboard = "nova-hypervisor",
    meta = "{{ $value }} instances"
  }
  ANNOTATIONS {
    summary = "Openstack Nova Instance Stuck in Starting state metric",
    description = "Nova Instance Stuck in Starting state over 15mins in {{ $labels.host }}",
  }

ALERT OpenstackNovaInstanceStuckSpawning
  IF sum(openstack_compute_stuck_instances_count_gauge{vm_state="spawning"}) by (host) > 0
  FOR 5m
  LABELS {
    service = "nova",
    severity = "info",
    tier = "openstack",
    dashboard = "nova-hypervisor",
    meta = "{{ $value }} instances"
  }
  ANNOTATIONS {
    summary = "Openstack Nova Instance Stuck in Spawning state metric",
    description = "Nova Instance Stuck in Spawning state over 15mins in {{ $labels.host }}",
  }

ALERT OpenstackNovaInstanceStuckRebooting
  IF sum(openstack_compute_stuck_instances_count_gauge{vm_state="rebooting"}) by (host) > 0
  FOR 5m
  LABELS {
    service = "nova",
    severity = "info",
    tier = "openstack",
    dashboard = "nova-hypervisor",
    meta = "{{`{{ $value }}`}} instances",
    {{ if .Values.ops_docu_url -}}
      playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/nova/delete_stuck_instance.html/#Rebooting",
    {{- end }}  }
  ANNOTATIONS {
    summary = "Openstack Nova Instance Stuck in Rebooting state metric",
    description = "Nova Instance Stuck in Rebooting state over 15mins in {{ $labels.host }}",
  }
