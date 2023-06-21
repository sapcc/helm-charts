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
