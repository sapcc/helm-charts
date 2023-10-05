groups:
- name: kubelet-stats-metrics.alerts
  rules:
  - alert: PodEphemeralStorageUsage
    expr: kubelet_stats_ephemeral_storage_pod_usage / kubelet_stats_ephemeral_storage_pod_capacity >= 0.1
    for: 1h
    labels:
      tier: k8s
      service: resources
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: storage
      meta: "Pod {{`{{ $labels.pod_namespace }}/{{ $labels.pod_name }}`}} is using more than 10% of the node's ephemeral storage."
    annotations:
      summary: "Pod {{`{{ $labels.pod_namespace }}/{{ $labels.pod_name }}`}} is using more than 10% of available ephemeral storage for the last hour."
      description: "Pod {{`{{ $labels.pod_namespace }}/{{ $labels.pod_name }}`}} is using more than 10% of node {{`{{ $labels.node_name }}`}} ephemeral storage. Please check with the service owner if this is the expected behavior."
  - alert: NodeEphemeralStorageUsage
    expr: sum by (node_name) (kubelet_stats_ephemeral_storage_pod_usage / kubelet_stats_ephemeral_storage_pod_capacity) > 0.5
    for: 15m
    labels:
      tier: k8s
      service: resources
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: storage
      meta: "Ephemeral storage total usage on node {{`{{ $labels.node_name }}`}} exceeds 50% of root disk size."
    annotations:
      summary: "Ephemeral storage exceeds 50% of root disk size for the last 15m."
      description: "Ephemeral storage total usage on node {{`{{ $labels.node_name }}`}} exceeds 50% of root disk size. Services depending on ephemeral storage might be affected when running out of disk space. Please check which services are filling up ephemeral storage and talk to the service owner."
