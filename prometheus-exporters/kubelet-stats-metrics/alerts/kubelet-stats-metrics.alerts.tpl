groups:
- name: kubelet-stats-metrics.alerts
  rules:
  - alert: PodEphemeralStorageUsage
    expr: (kubelet_stats_ephemeral_storage_pod_usage / kubelet_stats_ephemeral_storage_pod_capacity >= 0.3) * on (pod_name) group_left (label_ccloud_support_group) (label_replace(kube_pod_labels, "pod_name", "$1", "pod", "(.*)"))
    for: 1h
    labels:
      tier: k8s
      service: resources
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: storage
      meta: "Pod {{`{{ $labels.pod_namespace }}/{{ $labels.pod_name }}`}} is using more than 30% of the node's ephemeral storage."
    annotations:
      summary: "Pod {{`{{ $labels.pod_namespace }}/{{ $labels.pod_name }}`}} is using more than 30% of available ephemeral storage for the last hour."
      description: "Pod {{`{{ $labels.pod_namespace }}/{{ $labels.pod_name }}`}} is using more than 30% of node {{`{{ $labels.node_name }}`}} ephemeral storage. Please check with the service owner if this is the expected behavior."
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
