groups:
- name: calico.alerts
  rules:

    ### Calico ###

    - alert: CalicoBgpNeighborSessionDown
      expr: sum by (instance) (bird_protocol_up{state="Established"}) < {{ .Values.bgpNeighborCount }}
      for: 30m
      labels:
        tier: k8s
        service: calico
        severity: warning
        context: availability
        support_group: containers
        playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor"
      annotations:
        description: Node {{`{{ $labels.node }}`}} has less than {{ .Values.bgpNeighborCount }} BGP neighbors. BGP peer {{`{{ $labels.neighbor }}`}} is not established. Network datapath threatened! Switch upgrades or misconfiguration?
        summary: Node {{`{{ $labels.node }}`}} has less than {{ .Values.bgpNeighborCount }} BGP neighbors.


    - alert: CalicoBgpNeighborSessionAllDown
        expr: sum by (instance) (bird_protocol_up{state="Established"}) == 0
        for: 10m
        labels:
            tier: k8s
            service: calico
            severity: warning
            context: availability
            support_group: containers
            playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor"
        annotations:
            description: Node {{`{{ $labels.node }}`}} has no BGP neighbors. Network datapath is down! Switch upgrades or misconfiguration?
            summary: Node {{`{{ $labels.node }}`}} has no BGP neighbors.