groups:
- name: apiserver.alerts
  rules:
  - alert: KubernetesApiServerAllDown
    expr: count(up{job="kubernetes-apiserver"} == 0) == count(up{job="kubernetes-apiserver"})
    for: 5m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: warning
      context: apiserver
      meta: "{{`{{ $labels.instance }}`}}"
      dashboard: kubernetes-health
    annotations:
      description: Kubernetes API is unavailable!
      summary: All apiservers are down. Kubernetes API is unavailable!

  - alert: KubernetesApiServerDown
    expr: up{job="kubernetes-apiserver"} == 0
    for: 15m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: warning
      context: apiserver
      meta: "{{`{{ $labels.instance }}`}}"
      dashboard: kubernetes-node?var-server={{`{{$labels.instance}}`}}
    annotations:
      description: ApiServer on {{`{{ $labels.instance }}`}} is DOWN.
      summary: An ApiServer is DOWN

  - alert: KubernetesApiServerScrapeMissing
    expr: absent(up{job="kubernetes-apiserver"})
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: info
      context: apiserver
      dashboard: kubernetes-health
    annotations:
      description: ApiServer cannot be scraped
      summary: ApiServers failed to be scraped

  - alert: KubernetesApiServerLatency
    expr: max(histogram_quantile(0.99, sum without (instance,node,resource) (apiserver_request_latencies_bucket{verb!~"CONNECT|WATCHLIST|WATCH|LIST",resource!~"persistentvolumes|customresourcedefinitions",subresource!="log|persistentvolumes"})) / 1e6 > 3.0)
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: k8s
      severity: info
      context: apiserver
      dashboard: kubernetes-apiserver
    annotations:
      description: ApiServerLatency is expected to hover around 1-2s. It is currently unusually high for at least 1 resource! 
      summary: ApiServerLatency is unusally high

  - alert: KubernetesApiServerEtcdAccessLatency
    expr: etcd_request_latencies_summary{quantile="0.99"} / 1e6 > 1.0
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: etcd
      severity: info
      context: apiserver
      dashboard: kubernetes-apiserver
    annotations:
      description: Latency for apiserver to access etcd is higher than 1s
      summary: Access to etcd is slow
