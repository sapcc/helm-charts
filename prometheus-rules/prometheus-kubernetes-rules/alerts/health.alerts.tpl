# vi:syntax=yaml
groups:
- name: kubernetes.alerts
  rules:
  - alert: KubernetesNodeManyNotReady
    expr: count((kube_node_status_condition{condition="Ready",status="true"} unless on (node) kube_node_labels{label_cloud_sap_maintenance_state="in-maintenance"}) == 0) > 2
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: critical
      context: node
      meta: "{{`{{ $value }}`}} nodes NotReady"
      dashboard: kubernetes-health
      playbook: docs/support/playbook/kubernetes/k8s_node_not_ready.html
    annotations:
      summary: Many Nodes are NotReady
      description: "{{`{{ $value }}`}} nodes are NotReady for more than an hour"

  - alert: KubernetesNodeNotReady
    expr: sum by(node) (kube_node_status_condition{condition="Ready",status="true"} == 0)
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: warning
      context: node
      meta: "{{`{{ $labels.node }}`}} is NotReady"
      dashboard: nodes?var-server={{`{{$labels.node}}`}}
      playbook: docs/support/playbook/kubernetes/k8s_node_not_ready.html
      inhibited_by: node-maintenance
    annotations:
      summary: Node status is NotReady
      description: Node {{`{{ $labels.node }}`}} is NotReady for more than an hour

  - alert: KubernetesNodeNotReadyFlapping
    expr: changes(kube_node_status_condition{condition="Ready",status="true"}[15m]) > 2
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: warning
      context: node
      meta: "{{`{{ $labels.node }}`}}"
      dashboard: "nodes?var-server={{`{{$labels.node}}`}}"
    annotations:
      summary: Node readiness is flapping
      description: Node {{`{{ $labels.node }}`}} is flapping between Ready and NotReady

  - alert: KubernetesKubeStateMetricsScrapeFailed
    expr: absent(up{app="kube-state-metrics"})
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: warning
      context: node
      dashboard: kubernetes-health
    annotations:
      description: Failed to scrape kube-state-metrics. Metrics on the cluster state might be outdated. Check the kube-monitoring/kube-state-metrics deployment.
      summary: Kube state metrics scrape failed

  - alert: KubernetesPodRestartingTooMuch
    expr: (sum by(pod, namespace, container, ) (rate(kube_pod_container_status_restarts_total[15m]))) * on (pod, container) group_left(label_alert_tier, label_alert_service) kube_pod_labels{} > 0
    for: 1h
    labels:
      tier: {{ include "alertTierLabelOrDefault" .Values.tier }}
      service: {{ include "alertServiceLabelOrDefault" "resources" }}
      severity: warning
      context: pod
      meta: "Pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} is restarting constantly"
    annotations:
      description: Container {{`{{ $labels.container }}`}} of pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} is restarting constantly
      summary: Pod is in a restart loop

  - alert: KubernetesTooManyOpenFiles
    expr: 100*process_open_fds{job=~"kubernetes-kubelet|kubernetes-apiserver"} / process_max_fds > 50
    for: 10m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: warning
      context: system
      meta: "{{`{{ $labels.node }}`}}"
      dashboard: nodes?var-server={{`{{$labels.node}}`}}
    annotations:
      description: "{{`{{ $labels.job }}`}} on {{`{{ $labels.node }}`}} is using {{`{{ $value }}`}}% of the available file/socket descriptors"
      summary: Too many open file descriptors

  - alert: KubernetesPVCPendingOrLost
    expr: kube_persistentvolumeclaim_status_phase{phase=~"Pending|Lost"} == 1
    for: 15m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: info
      context: pvc
    annotations:
      description: "PVC {{`{{ $labels.namespace }}`}}/{{`{{ $labels.persistentvolumeclaim }}`}} stuck in phase {{`{{ $labels.phase }}`}} since 15 min"
      summary: "PVC stuck in phase {{`{{ $labels.phase }}`}}"

  - alert: KubernetesDeploymentInsufficientReplicas
    expr: sum(kube_deployment_status_replicas) by (namespace,deployment) < sum(kube_deployment_spec_replicas) by (namespace,deployment)
    for: 10m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: deployment
      severity: info
      context: deployment
      meta: "{{`{{ $labels.namespace }}`}}/{{`{{ $labels.deployment }}`}} has insufficient replicas"
    annotations:
      description: Deployment {{`{{ $labels.namespace }}`}}/{{`{{ $labels.deployment }}`}} only {{`{{ $value }}`}} replica available, which is less then desired
      summary: Deployment has less than desired replicas since 10m

  - alert: ManyPodsNotReadyOnNode
    expr: sum by (node) (kube_pod_status_ready_normalized{condition="true"}) / sum by (node) (kube_pod_status_phase_normalized{phase="Running"}) < 0.75 and sum by(node) (kube_node_status_condition{condition="Ready",status="true"} == 1)
    for: 30m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: critical
      playbook: docs/support/playbook/kubernetes/k8s-pods-not-ready-on-ready-node.html
    annotations:
      description: "{{`{{ humanizePercentage $value }}`}} of pods are ready on node {{`{{$labels.node}}`}}. This might by due to <https://github.com/kubernetes/kubernetes/issues/84931| kubernetes #84931>. In that case a restart of the kubelet is required."
      summary: "Less then 75% of pods ready on node"

  - alert: PodNotReady
    # alert on pods that are not ready but in the Running phase on a Ready node
    expr: kube_pod_status_phase_normalized{phase="Running"} * on (pod,node, namespace)kube_pod_status_ready_normalized{condition="false"} * on (node) group_left() sum by(node) (kube_node_status_condition{condition="Ready",status="true"}) == 1
    for: 2h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: info
    annotations:
      description: "The pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} is not ready for more then 2h."
      summary: "Pod not ready for a long time"
