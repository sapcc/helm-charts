groups:
- name: oomkill.alerts
  rules:
  - alert: PodOOMExceedingLimits
    expr: predict_linear(container_memory_usage_bytes{pod_name=~".+"}[1h],  8* 3600) > ON (pod_name, namespace)  label_replace(kube_pod_container_resource_limits_memory_bytes{pod=~".+"}, "pod_name", "$1", "pod", "(.*)") 
    for: 5m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: resources
      severity: info
      context: memory
      meta: "{{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod_name }}`}}"
    annotations:
      summary: Pod will likely exceed memory limits in 8h
      description: The pod {{`{{ $labels.namespace }}`}}/{{`{{ $labels.pod_name }}`}} will exceed its memory limit in 8h.
