groups:
- name: oomkill.alerts
  rules:
  - alert: PodOOMExceedingLimits
    expr: max(predict_linear(container_memory_working_set_bytes{pod_name=~".+"}[1h], 8 * 3600)) by (container_name, pod_name, namespace)  >  max(label_replace(label_replace(kube_pod_container_resource_limits_memory_bytes{pod=~".+"}, "pod_name", "$1", "pod", "(.*)"), "container_name", "$1", "container", "(.*)")) by (container_name, pod_name, namespace)
    for: 5m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: resources
      severity: info
      context: memory
      meta: "{{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod_name }}`}}/{{`{{ $labels.container_name }}`}}"
    annotations:
      summary: Pod will likely exceed memory limits in 8h
      description: The {{`{{ $labels.container_name }}`}} container of pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod_name }}`}} will exceed its memory limit in 8h.
