groups:
- name: calico.alerts
  rules:

    ### Calico ###

    - alert: CalicoBgpNeighborSessionDown
      expr: sum by (node) (bird_protocol_up{proto="BGP",state="Established"}) < {{ .Values.bgpNeighborCount }}
      for: 30m
      labels:
        tier: k8s
        service: {{ .Values.alerts.service }}
        severity: warning
        context: availability
        support_group: {{ .Values.alerts.supportGroup }}
        playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor"
      annotations:
        description: Node {{`{{ $labels.node }}`}} has less than {{ .Values.bgpNeighborCount }} BGP neighbors. BGP peer {{`{{ $labels.neighbor }}`}} is not established. Network datapath threatened! Switch upgrades or misconfiguration?
        summary: Node {{`{{ $labels.node }}`}} has less than {{ .Values.bgpNeighborCount }} BGP neighbors.


    - alert: CalicoBgpNeighborSessionAllDown
      expr: sum by (node) (bird_protocol_up{proto="BGP",state="Established"}) == 0
      for: 10m
      labels:
        tier: k8s
        service: {{ .Values.alerts.service }}
        severity: critical
        context: availability
        support_group: {{ .Values.alerts.supportGroup }}
        playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor"
      annotations:
        description: Node {{`{{ $labels.node }}`}} has no BGP neighbors. Network datapath is down! Switch upgrades or misconfiguration?
        summary: Node {{`{{ $labels.node }}`}} has no BGP neighbors.

    - alert: CalicoScrapeMissing
      expr: count(up{job="kubernetes-kubelet"} == 1) > count(up{job="calico-bird-monitoring"} == 1)
      for: 30m
      labels:
        tier: k8s
        service: {{ .Values.alerts.service }}
        severity: warning
        context: availability
        support_group: {{ .Values.alerts.supportGroup }}
        playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor"
      annotations:
        description: Calico is not running on all nodes that are Ready.
        summary: Calico is not running on all bare metal nodes that are Ready. Network datapath threatened!

    - alert: CalicoNodeNotReady
      expr: kube_pod_container_status_ready{container="calico-node"} == 0
      for: 30m
      labels:
        tier: k8s
        service: {{ .Values.alerts.service }}
        severity: warning
        context: availability
        support_group: {{ .Values.alerts.supportGroup }}
        playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor"
      annotations:
        description: Calico-Node Pod is not Ready on all nodes.
        summary: Calico-Node is not healthy on all bare metal nodes that are Ready. Risk of stale BGP advertisement. Network datapath threatened!
