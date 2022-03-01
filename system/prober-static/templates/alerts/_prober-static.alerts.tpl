groups:
- name: apiserver-k8s.alerts
  rules:

    ### Kubernetes apiserver probes ###
    - alert: KubernetesApiServerProbeDown
      expr: probe_success{job="k8s-apiserver-probe-https"} == 0
      for: 15m
      labels:
        severity: warning
        tier: k8s
        service: k8s
        context: apiserver
        dashboard: kubernetes-health
        playbook: docs/support/playbook/kubernetes/k8s_apiserver_down
      annotations:
        description: Failed to probe ApiServer on {{`{{ $labels.instance }}`}}. 
        summary: An ApiServer is DOWN
