groups:
- name: kube-parrot.alerts
  rules:

    ### Kube Parrot ###

    - alert: KubeParrotBgpNeighborSessionDown
      expr: sum by (node) (kube_parrot_bgp_neighbor_session_status{status="established"}) < {{ .Values.parrot.bgpNeighborCount }}
      for: 5m
      labels:
        tier: k8s
        service: kube-parrot
        severity: critical
        context: availability
        playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor.html"
      annotations:
        description: Node {{`{{ $labels.node }}`}} has less than {{ .Values.parrot.bgpNeighborCount }} BGP neighbors. Network datapath threatened!
        summary: Node {{`{{ $labels.node }}`}} has less than {{ .Values.parrot.bgpNeighborCount }} BGP neighbors.

    - alert: KubeParrotBgpNeighborMissingRouteAdvertisement
      expr: sum by (node,neighbor) (kube_parrot_bgp_neighbor_advertised_route_count_total) < 1
      for: 5m
      labels:
        tier: k8s
        service: kube-parrot
        severity: critical
        context: availability
        playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor.html"
      annotations:
        description: Node {{`{{ $labels.node }}`}} is not advertising any prefixes to its BGP neighbors. Network datapath threatened!
        summary: Node {{`{{ $labels.node }}`}} is not advertising any prefixes to its BGP neighbors.
