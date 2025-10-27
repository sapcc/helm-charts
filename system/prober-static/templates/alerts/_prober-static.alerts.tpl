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
        support_group: containers
        dashboard: kubernetes-health
        playbook: docs/support/playbook/kubernetes/k8s_apiserver_down
      annotations:
        description: Failed to probe ApiServer on {{`{{ $labels.instance }}`}}. 
        summary: An ApiServer is DOWN

    ### Controlplane Filer probes ###
    - alert: KubernetesCpFilerProbeDown
      expr: probe_success{job=~"cp-nfs-filer-probe.*"} == 0
      for: 15m
      labels:
        severity: warning
        tier: k8s
        service: k8s
        support_group: containers
        playbook: docs/support/playbook/kubernetes/k8s_cp_filer_down
      annotations:
        description: |
          Failed to probe Controlplane filer on {{`{{ $labels.instance }}`}} in region {{`{{ $labels.probeRegion }}`}}.
          Nodes in {{`{{ $labels.probeRegion }}`}} cannot mount NFS Persistent Volumes.
          Double check NFS IP address in Netbox, verify reachability and involve Storage and/or Network teams.
        summary: Controlplane filer NFS target is DOWN in {{`{{ $labels.probeRegion }}`}}
