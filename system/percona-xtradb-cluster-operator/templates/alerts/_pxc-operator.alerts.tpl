- name: pxc-operator.alerts
  rules:
  - alert: PerconaXtraDBClusterOperatorNotReady
    expr: (sum(kube_pod_status_ready_normalized{condition="true", pod=~"percona-xtradb-cluster-operator.*"}) < 1)
    for: 10m
    labels:
      severity: info  # New Alerts MUST be initially implemented Info.
      context: availability
      service: percona-xtradb-cluster-operator
      tier: os
      playbook: "docs/support/playbook/database/percona_xtradb_cluster_operator_not_ready/"
      support_group: network-api
    annotations:
      description: percona-xtradb-cluster-operator is not ready for 10 minutes.
      summary: percona-xtradb-cluster-operator is not ready for 10 minutes. Please check the pod.
