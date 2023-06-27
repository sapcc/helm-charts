# vi:syntax=yaml


### Pod resource usage ###
groups:
- name: pod.alerts
  rules:
  - alert: ContainerLowMemoryUsage
    expr: floor(sum(container_memory_working_set_bytes{pod!=""}) BY (namespace, pod, container) / ON (namespace, pod, container) sum(kube_pod_container_resource_requests_memory_bytes > 0) BY (namespace, pod, container) * 100) < 10
    for: 1d
    labels:
      tier: {{ include "alertTierLabelOrDefault" .Values.tier }}
      service: {{ include "serviceFromLabelsOrDefault" "k8s" }}
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: info
      context: container
      meta: "Low RAM usage on {{`{{ $labels.container }}`}}"
      playbook: docs/support/playbook/kubernetes/k8s_container_pod_low_ram_usage
    annotations:
      summary: Low RAM usage on container
      description: "Container {{`{{ $labels.container }}`}} of pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} Memory usage is under 10% for 24 hours. Consider reducing the requested memory."
  - alert: ContainerHighMemoryUsage
    expr: ceil(sum(container_memory_working_set_bytes{pod!=""}) BY (namespace, pod, container) / ON (namespace, pod, container) sum(kube_pod_container_resource_requests_memory_bytes > 0) BY (namespace, pod, container) * 100) > 150
    for: 1d
    labels:
      tier: {{ include "alertTierLabelOrDefault" .Values.tier }}
      service: {{ include "serviceFromLabelsOrDefault" "k8s" }}
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: info
      context: container
      meta: "High RAM usage on {{`{{ $labels.container }}`}}"
      playbook: docs/support/playbook/kubernetes/k8s_container_pod_high_ram_usage
    annotations:
      summary: High RAM usage on container
      description: "Container {{`{{ $labels.container }}`}} of pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} Memory usage is over 150% for 24 hours. Consider raising the requested memory."
  - alert: PodWithoutConfiguredMemoryRequests
    expr: count by (namespace, app, pod, container)(sum by (namespace, app, pod,container)(kube_pod_container_info{container!=""}) unless sum by (namespace,app,pod,container)(kube_pod_container_resource_requests{resource="ram"}))
    for: 1d
    labels:
      tier: {{ include "alertTierLabelOrDefault" .Values.tier }}
      service: {{ include "serviceFromLabelsOrDefault" "k8s" }}
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: info
      context: pod
      meta: "No RAM requests configured for {{`{{ $labels.pod }}`}}"
      playbook: docs/support/playbook/kubernetes/k8s_pod_no_ram_requests
    annotations:
      summary: No RAM requests configured for pod
      description: "Pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} has no Memory requests configured."
  - alert: PodWithoutConfiguredCPURequests
    expr: count by (namespace, app, pod, container)(sum by (namespace, app, pod,container)(kube_pod_container_info{container!=""}) unless sum by (namespace,app,pod,container)(kube_pod_container_resource_requests{resource="cpu"}))
    for: 1d
    labels:
      tier: {{ include "alertTierLabelOrDefault" .Values.tier }}
      service: {{ include "serviceFromLabelsOrDefault" "k8s" }}
      support_group: {{ include "supportGroupFromLabelsOrDefault" "containers" }}
      severity: info
      context: pod
      meta: "No CPU requests configured for {{`{{ $labels.pod }}`}}"
      playbook: docs/support/playbook/kubernetes/k8s_pod_no_cpu_requests
    annotations:
      summary: No CPU requests configured for pod
      description: "Pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod }}`}} has no CPU requests configured."
