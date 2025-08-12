- name: pxc-operator-kubernetes.alerts
  rules:
  - alert: PerconaXtraDBClusterOperatorNotReady
    expr: (sum(kube_pod_status_ready_normalized{condition="true", pod=~"percona-xtradb-cluster-operator.*"}) < 1)
    for: 10m
    labels:
      severity: info  # New Alerts MUST be initially implemented Info.
      context: availability
      service: {{  index .Values "owner-info" "service" | quote }}
      tier: os
      playbook: 'https://operations.global.cloud.sap/docs/support/playbook/database/percona_xtradb_cluster_operator_not_ready/'
      support_group: {{  index .Values "owner-info" "support-group" | quote }}
    annotations:
      description: percona-xtradb-cluster-operator is not ready for 10 minutes.
      summary: percona-xtradb-cluster-operator is not ready for 10 minutes. Please check the pod.
