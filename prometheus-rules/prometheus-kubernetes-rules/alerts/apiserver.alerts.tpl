# vi:syntax=yaml
groups:
- name: apiserver.alerts
  rules:
  - alert: KubernetesApiServerAllDown
    expr: count(up{job="kubernetes-apiserver"} == 0) == count(up{job="kubernetes-apiserver"})
    for: 5m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      support_group: {{ required ".Values.supportGroup missing" .Values.supportGroup }}
      service: {{ required ".Values.service missing" .Values.service }}
      severity: warning
      context: apiserver
      meta: "{{`{{ $labels.instance }}`}}"
      dashboard: kubernetes-health
      playbook: 'https://operations.global.cloud.sap/docs/support/playbook/kubernetes/k8s_apiserver_down'
    annotations:
      description: Kubernetes API is unavailable!
      summary: All apiservers are down. Kubernetes API is unavailable!

  - alert: KubernetesApiServerDown
    expr: up{job="kubernetes-apiserver"} == 0
    for: 15m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      support_group: {{ required ".Values.supportGroup missing" .Values.supportGroup }}
      service: {{ required ".Values.service missing" .Values.service }}
      severity: warning
      context: apiserver
      meta: "{{`{{ $labels.instance }}`}}"
      dashboard: nodes?var-server={{`{{$labels.instance}}`}}
      playbook: 'https://operations.global.cloud.sap/docs/support/playbook/kubernetes/k8s_apiserver_down'
    annotations:
      description: ApiServer on {{`{{ $labels.instance }}`}} is DOWN.
      summary: An ApiServer is DOWN

  - alert: KubernetesApiServerScrapeMissing
    expr: up{job=~".*apiserver.*"} == 0 or absent(up{job=~".*apiserver.*"})
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      support_group: {{ required ".Values.supportGroup missing" .Values.supportGroup }}
      service: {{ required ".Values.service missing" .Values.service }}
      severity: info
      context: apiserver
      dashboard: kubernetes-health
    annotations:
      description: ApiServer cannot be scraped
      summary: ApiServers failed to be scraped

  - alert: KubernetesApiServerLatency
    expr: histogram_quantile(0.99, sum(rate(apiserver_request_latencies_bucket{verb!~"CONNECT|WATCHLIST|WATCH|LIST",subresource!="log"}[5m])) by (resource, le)) / 1e6 > 2
    for: 30m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      support_group: {{ required ".Values.supportGroup missing" .Values.supportGroup }}
      service: {{ required ".Values.service missing" .Values.service }}
      support_group: containers
      severity: info
      context: apiserver
      dashboard: kubernetes-apiserver
    annotations:
      description: ApiServerLatency for {{`{{ $labels.resource }}`}} is higher then usual for the past 15 minutes. Inspect apiserver logs for the root cause.
      summary: ApiServerLatency is unusally high

  - alert: KubeAggregatedAPIDown
    # We have to filter by job here because somehow the kubelet is also exporting this metric ?! and in admin/virtual/kubernikus we also scape apiservers in the
    # kubernikus namespace
    expr: (1 - max by(name, namespace)(avg_over_time(aggregator_unavailable_apiservice{job="kubernetes-apiserver"}[10m]))) * 100 < 85
    for: 5m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      support_group: {{ required ".Values.supportGroup missing" .Values.supportGroup }}
      service: {{ required ".Values.service missing" .Values.service }}
      severity: warning
      context: apiserver
    annotations:
      description: "Kubernetes aggregated API {{`{{ $labels.namespace }}`}}/{{`{{ $labels.name }}`}} has been only {{`{{ $value | humanize }}`}}% available over the last 10m. Run `kubectl get apiservice | grep -v Local` and confirm the services of aggregated APIs have active endpoints."
      summary: Kubernetes aggregated API is down.
