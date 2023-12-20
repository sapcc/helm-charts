# vi:syntax=yaml
groups:
- name: kubelet.alerts
  rules:
  - alert: ManyKubeletDown
    expr: count(count(up{job="kubernetes-kubelet"} unless on (node) (kube_node_labels{label_cloud_sap_maintenance_state="in-maintenance"} or kube_node_labels{label_kubernetes_cloud_sap_role="storage"})) - sum(up{job="kubernetes-kubelet"} unless on (node) (kube_node_labels{label_cloud_sap_maintenance_state="in-maintenance"} or kube_node_labels{label_kubernetes_cloud_sap_role="storage"}))) > 4
    for: 10m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: kubelet
      support_group: containers
      severity: critical
      context: kubelet
      dashboard: kubernetes-health
      playbook: docs/support/playbook/kubernetes/k8s_node_not_ready
    annotations:
      description: Many Kubelets are DOWN
      summary: More than 2 Kubelets are DOWN

  - alert: KubeletDown
    expr: up{job="kubernetes-kubelet"} == 0
    for: 10m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: kubelet
      support_group: containers
      severity: warning
      context: kubelet
      meta: "{{`{{ $labels.node }}`}}"
      dashboard: kubernetes-health
      playbook: docs/support/playbook/kubernetes/k8s_node_not_ready
      inhibited_by: node-maintenance
    annotations:
      description: Kublet on {{`{{ $labels.node }}`}} is DOWN.
      summary: A Kubelet is DOWN

  - alert: KubeletTooManyPods
    expr: kubelet_running_pod_count > 225
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: kubelet
      support_group: containers
      severity: warning
      context: kubelet
      meta: "{{`{{ $labels.node }}`}}"
      dashboard: nodes?var-server={{`{{$labels.node}}`}}
    annotations:
      description: Kubelet is close to pod limit
      summary: Kubelet {{`{{ $labels.node }}`}} is running {{`{{ $value }}`}} pods, close to the limit of 250

  - alert: KubeletFull
    expr: kubelet_running_pod_count >= 250
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: kubelet
      support_group: containers
      severity: warning
      context: kubelet
      meta: "{{`{{ $labels.node }}`}}"
      dashboard: nodes?var-server={{`{{ $labels.node }}`}}
    annotations:
      description: Kubelet is full
      summary: Kubelet Kubelet {{`{{$labels.node}}`}} is running {{`{{ $value }}`}} pods. That's too much!

  - alert: KubeletHighNumberOfGoRoutines
    expr: go_goroutines{job="kubernetes-kubelet"} > {{ default "5000" .Values.kubelet.goroutinesHighCount }}
    for: 5m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      support_group: containers
      severity: warning
      context: kubelet
      meta: "{{`{{ $labels.node }}`}}"
    annotations:
      description: Kublet on {{`{{ $labels.node }}`}} might be unresponsive due to a high number of go routines
      summary: High number of Go routines

  - alert: KubeletPredictHighNumberOfGoRoutines
    expr: abs(predict_linear(go_goroutines{job="kubernetes-kubelet"}[1h], 2*3600)) > {{ default "10000" .Values.kubelet.goroutinesPredictHighCount }}
    for: 5m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      support_group: containers
      severity: warning
      context: kubelet
      meta: "{{`{{ $labels.node }}`}}"
    annotations:
      description: Kublet on {{`{{$labels.node}}`}} might become unresponsive due to a high number of go routines within 2 hours, take a look at the node and wait if it stabilizes.
      summary: Predicting high number of Go routines

  - alert: KubeletManyRequestErrors
    expr: |
      (sum(rate(rest_client_requests_total{code=~"5.*", component="kubelet"}[5m])) by (node)
      /
      sum(rate(rest_client_requests_total{component="kubelet"}[5m])) by (node))
      * 100 > 1
    for: 10m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      support_group: containers
      severity: warning
      context: kubelet
      meta: "Many 5xx responses for Kubelet on {{`{{ $labels.node }}`}} "
    annotations:
      description: "{{`{{ printf \"%0.0f\" $value }}`}}% of requests from kubelet on {{`{{ $labels.node }}`}} error"
      summary: Many 5xx responses for Kubelet
