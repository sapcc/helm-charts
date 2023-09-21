groups:
- name: kubelet-stats-metrics.alerts
  rules:
  - alert: PodEphemeralStorageUsage
    expr: 
    for: 5m
    labels:
      tier: k8s
      service: resources
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: info
      context: storage
      meta: ""
    annotations:
      summary: 
      description: 
