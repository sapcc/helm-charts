# vi:syntax=yaml
groups:
- name: kubernetes.alerts
  rules:
  - alert: KubernetesNodeManyNotReady
    expr: count((kube_node_status_condition{condition="Ready",status="true"} unless on (node) (kube_node_labels{label_cloud_sap_maintenance_state="in-maintenance"} or kube_node_labels{label_kubernetes_cloud_sap_role="storage"})) == 0) > 4
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: critical
      support_group: containers
      context: node
      meta: "{{`{{ $value }}`}} nodes NotReady"
      dashboard: kubernetes-health
      playbook: docs/support/playbook/kubernetes/k8s_node_not_ready
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
      support_group: containers
      context: node
      meta: "{{`{{ $labels.node }}`}} is NotReady"
      dashboard: nodes?var-server={{`{{$labels.node}}`}}
      playbook: docs/support/playbook/kubernetes/k8s_node_not_ready
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
      support_group: containers
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
      support_group: containers
      context: node
      dashboard: kubernetes-health
    annotations:
      description: Failed to scrape kube-state-metrics. Metrics on the cluster state might be outdated. Check the kube-monitoring/kube-state-metrics deployment.
      summary: Kube state metrics scrape failed

  - alert: KubernetesPodRestartingTooMuch
    expr: (sum by(pod, namespace, container) (rate(kube_pod_container_status_restarts_total[15m]))) * on (pod) group_left(label_alert_tier, label_alert_service, label_ccloud_support_group, label_ccloud_service) (max without (uid) (kube_pod_labels)) > 0
    for: 1h
    labels:
      tier: {{ include "alertTierLabelOrDefault" .Values.tier }}
      service: {{ include "serviceFromLabelsOrDefault" "k8s" }}
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: pod
      meta: "Pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} is restarting constantly"
    annotations:
      description: Container {{`{{ $labels.container }}`}} of pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} is restarting constantly.{{`{{ if eq $labels.support_group "containers"}}`}} Is `owner-info` set --> Contact respective service owner! If not, try finding him/her and make sure, `owner-info` is set!{{`{{ end }}`}}
      summary: Pod is in a restart loop

  - alert: KubernetesTooManyOpenFiles
    expr: 100*process_open_fds{job=~"kubernetes-kubelet|kubernetes-apiserver"} / process_max_fds > 50
    for: 10m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      support_group: containers
      severity: warning
      context: system
      meta: "{{`{{ $labels.node }}`}}"
      dashboard: nodes?var-server={{`{{$labels.node}}`}}
    annotations:
      description: "{{`{{ $labels.job }}`}} on {{`{{ $labels.node }}`}} is using {{`{{ $value }}`}}% of the available file/socket descriptors"
      summary: Too many open file descriptors

  - alert: KubernetesDeploymentInsufficientReplicas
    expr: (sum(kube_deployment_status_replicas) by (namespace,deployment) < sum(kube_deployment_spec_replicas) by (namespace,deployment)) * on (namespace, deployment) group_left(label_ccloud_support_group, label_ccloud_service) (kube_deployment_labels)
    for: 10m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: {{ include "serviceFromLabelsOrDefault" "k8s" }}
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      context: deployment
      meta: "{{`{{ $labels.namespace }}`}}/{{`{{ $labels.deployment }}`}} has insufficient replicas"
    annotations:
      description: Deployment {{`{{ $labels.namespace }}`}}/{{`{{ $labels.deployment }}`}} only {{`{{ $value }}`}} replica available, which is less then desired
      summary: Deployment has less than desired replicas since 10m

  - alert: PodNotReady
    # alert on pods that are not ready but in the Running phase on a Ready node
    expr: (kube_pod_status_phase_normalized{phase="Running"} * on(pod, node, namespace) kube_pod_status_ready_normalized{condition="false"} * on(node) group_left() sum by(node) (kube_node_status_condition{condition="Ready",status="true"}) == 1) * on(pod) group_left(label_alert_tier, label_alert_service, label_cc_support_group, label_ccloud_service) (max without(uid) (kube_pod_labels))
    for: 2h
    labels:
      tier: {{ include "alertTierLabelOrDefault" .Values.tier }}
      service: {{ include "serviceFromLabelsOrDefault" "k8s" }}
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: info
    annotations:
      description: "The pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} is not ready for more then 2h."
      summary: "Pod not ready for a long time"

  - alert: PrometheusMultiplePodScrapes
    expr: sum by(pod, namespace, label_alert_service, label_alert_tier, label_ccloud_service, label_ccloud_support_group) (label_replace((up * on(instance) group_left() (sum by(instance) (up{job=~".*pod-sd"}) > 1)* on(pod) group_left(label_alert_tier, label_alert_service, label_ccloud_support_group, label_ccloud_service) (max without(uid) (kube_pod_labels))) , "pod", "$1", "kubernetes_pod_name", "(.*)-[0-9a-f]{8,10}-[a-z0-9]{5}"))
    for: 30m
    labels:
      tier: {{ include "alertTierLabelOrDefault" .Values.tier }}
      service: {{ include "serviceFromLabelsOrDefault" "k8s" }}
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: warning
      playbook: docs/support/playbook/kubernetes/target_scraped_multiple_times
      meta: 'Prometheus is scraping {{`{{ $labels.pod }}`}} pods more than once.'
    annotations:
      description: Prometheus is scraping `{{`{{ $labels.pod }}`}}` pods in namespace `{{`{{ $labels.namespace }}`}}` multiple times. This is likely caused due to incorrectly placed scrape annotations.
      summary: Prometheus scrapes pods multiple times
