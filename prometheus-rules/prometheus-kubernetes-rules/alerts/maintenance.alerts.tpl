### Maintenance inhibition alerts ###

groups:
- name: maintenance.alerts
  rules:
  - alert: NodeInMaintenance
    expr: max by (node) (kube_node_labels{label_cloud_sap_maintenance_state="in-maintenance"}) == 1
    for: 2m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      support_group: containers
      severity: none
      context: node
      meta: "Node {{`{{ $labels.node }}`}} is in maintenance."
    annotations:
      summary: Node in maintenance
      description: "Node {{`{{ $labels.node }}`}} is in scheduled maintenance. Add the label `inhibited_by: node-maintenance` to alerts that should be inhibited while a node is in maintenance"

### Maintenance stuck alerts ###

  - alert: NodeStuckInMaintenance
{{- if eq .Values.global.clusterType "metal" }}
    expr: kube_node_labels{label_cloud_sap_esx_in_maintenance="false",label_cloud_sap_maintenance_state="in-maintenance"} * on (node) group_left() (kube_node_status_condition{condition="Ready",status="true"} == 0)
{{- else }}
    expr: kube_node_labels{label_cloud_sap_maintenance_state="in-maintenance"} * on (node) group_left() (kube_node_status_condition{condition="Ready",status="true"} == 0)
{{- end }}
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      support_group: containers
      severity: warning
      context: maintenance-controller
      meta: "Node {{`{{ $labels.node }}`}} is stuck in maintenance for 1 hour."
    annotations:
      summary: Node stuck in maintenance
      description: "Node {{`{{ $labels.node }}`}} is stuck on reboot after OS upgrade or hardware maintenance. Check node console."

### Flatcar version disparity ###
  - alert: FlatcarVersionDisparity
    expr: count by (cluster) (count by (label_flatcar_linux_update_v1_flatcar_linux_net_version,cluster) (kube_node_labels)) > 2
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      support_group: containers
      severity: warning
      context: maintenance-controller
      meta: "Cluster {{`{{ $labels.cluster }}`}} has a disparity in flatcar versions."
      playbook: docs/support/playbook/kubernetes/flatcar_version_disparity
    annotations:
      summary: More than 2 flatcar versions
      description: "Cluster {{`{{ $labels.cluster }}`}} has a disparity in flatcar versions. This indicates some issue with the maintenance-controller."
