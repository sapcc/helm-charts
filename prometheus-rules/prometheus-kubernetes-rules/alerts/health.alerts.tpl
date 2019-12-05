# vi:syntax=yaml
groups:
- name: kubernetes.alerts
  rules:
  - alert: KubernetesNodeManyNotReady
    expr: count(kube_node_status_condition{condition="Ready",status="true"} == 0) > 2
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
      dashboard: kubernetes-node?var-server={{`{{$labels.node}}`}}
      playbook: docs/support/playbook/kubernetes/k8s_node_not_ready.html
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
      meta: "{{`{{ $labels.instance }}`}}"
      dashboard: "kubernetes-node?var-server={{`{{$labels.instance}}`}}"
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
    expr: sum(rate(kube_pod_container_status_restarts_total[15m])) by (pod, namespace, container) > 0
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: resources
      severity: info
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
      meta: "{{`{{ $labels.instance }}`}}"
      dashboard: kubernetes-node?var-server={{`{{$labels.instance}}`}}
    annotations:
      description: "{{`{{ $labels.job }}`}} on {{`{{ $labels.instance }}`}} is using {{`{{ $value }}`}}% of the available file/socket descriptors"
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
    expr: sum(max(kube_pod_info) by (pod,node) * on (pod) group_left max(kube_pod_status_ready{condition="true"}) by (pod)) by (node) / sum(kube_pod_info) by (node) < 0.5 and sum by(node) (kube_node_status_condition{condition="Ready",status="true"} == 1)
    for: 30m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: warning
    annotations:
      description: "{{`{{ humanizePercentage $value }}`}} of pods are ready on node {{`{{$labels.node}}`}}. This might by due to <https://github.com/kubernetes/kubernetes/issues/84931| kubernetes #84931>. In that case a restart of the kubelet is required."
      summary: "Less then 50% of pods ready on node"

  - alert: PodNotReady
    # alert on pods that are not ready but in the Running phase on a Ready node
    expr: sum((kube_pod_info * on(node) group_left sum(kube_node_status_condition{condition="Ready", status="true"}) by (node)* on (pod) group_left sum(kube_pod_status_phase{phase="Running"}) by (pod) == 1)  *on (pod) group_left sum(kube_pod_status_ready{condition="true"}) by (pod)) by (pod,namespace) == 0
    for: 2h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: info
    annotations:
      description: "The pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} is not ready for more then 2h."
      summary: "Pod not ready for a long time"
