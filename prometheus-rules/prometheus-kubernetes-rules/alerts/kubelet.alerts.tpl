# vi:syntax=yaml
groups:
- name: kubelet.alerts
  rules:
  - alert: KubeletDown
    expr: up{job="kubernetes-kubelet"} == 0
    for: 10m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      support_group: {{ required ".Values.supportGroup missing" .Values.supportGroup }}
      service: {{ required ".Values.service missing" .Values.service }}
      severity: warning
      context: kubelet
      meta: "{{`{{ $labels.node }}`}}"
      dashboard: kubernetes-health
      playbook: docs/support/playbook/kubernetes/k8s_node_not_ready
      inhibited_by: node-maintenance
    annotations:
      description: Kublet on {{`{{ $labels.node }}`}} is DOWN.
      summary: A Kubelet is DOWN

  # Duplicated from maintenance.alerts. It has multiple occurrences; make sure you change all of them if you modify this. 
  - alert: NodeInMaintenance
    expr: max by (node) (kube_node_labels{label_cloud_sap_maintenance_state="in-maintenance"}) == 1
    for: 2m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      support_group: {{ required ".Values.supportGroup missing" .Values.supportGroup }}
      service: {{ required ".Values.service missing" .Values.service }}
      severity: info
      context: node
      meta: "Node {{`{{ $labels.node }}`}} is in maintenance."
    annotations:
      summary: Node in maintenance
      description: "Node {{`{{ $labels.node }}`}} is in scheduled maintenance. Add the label `inhibited_by: node-maintenance` to alerts that should be inhibited while a node is in maintenance"

  - alert: ManyKubeletDown
    expr: count(count(up{job="kubernetes-kubelet"} unless on (node) (kube_node_labels{label_cloud_sap_maintenance_state="in-maintenance"} or kube_node_labels{label_kubernetes_cloud_sap_role="storage"})) - sum(up{job="kubernetes-kubelet"} unless on (node) (kube_node_labels{label_cloud_sap_maintenance_state="in-maintenance"} or kube_node_labels{label_kubernetes_cloud_sap_role="storage"}))) > 4
    for: 10m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      support_group: {{ required ".Values.supportGroup missing" .Values.supportGroup }}
      service: {{ required ".Values.service missing" .Values.service }}
      severity: critical
      context: kubelet
      dashboard: kubernetes-health
      playbook: docs/support/playbook/kubernetes/k8s_node_not_ready
    annotations:
      description: Many Kubelets are DOWN
      summary: More than 2 Kubelets are DOWN

  - alert: KubeletTooManyPods
    expr: kubelet_running_pods > 225
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      support_group: {{ required ".Values.supportGroup missing" .Values.supportGroup }}
      service: {{ required ".Values.service missing" .Values.service }}
      severity: warning
      context: kubelet
      meta: "{{`{{ $labels.node }}`}}"
      dashboard: nodes?var-server={{`{{$labels.node}}`}}
    annotations:
      description: Kubelet is close to pod limit
      summary: Kubelet {{`{{ $labels.node }}`}} is running {{`{{ $value }}`}} pods, close to the limit of 250

  - alert: KubeletFull
    expr: kubelet_running_pods >= 250
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      support_group: {{ required ".Values.supportGroup missing" .Values.supportGroup }}
      service: {{ required ".Values.service missing" .Values.service }}
      severity: warning
      context: kubelet
      meta: "{{`{{ $labels.node }}`}}"
      dashboard: nodes?var-server={{`{{ $labels.node }}`}}
    annotations:
      description: Kubelet is full
      summary: Kubelet Kubelet {{`{{$labels.node}}`}} is running {{`{{ $value }}`}} pods. That's too much!

  - alert: KubeletManyRequestErrors
    expr: |
      (sum(rate(rest_client_requests_total{code=~"5.*", component="kubelet"}[5m])) by (node)
      /
      sum(rate(rest_client_requests_total{component="kubelet"}[5m])) by (node))
      * 100 > 1
    for: 10m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      support_group: {{ required ".Values.supportGroup missing" .Values.supportGroup }}
      service: {{ required ".Values.service missing" .Values.service }}
      severity: warning
      context: kubelet
      meta: "Many 5xx responses for Kubelet on {{`{{ $labels.node }}`}} "
    annotations:
      description: "{{`{{ printf \"%0.0f\" $value }}`}}% of requests from kubelet on {{`{{ $labels.node }}`}} error"
      summary: Many 5xx responses for Kubelet
