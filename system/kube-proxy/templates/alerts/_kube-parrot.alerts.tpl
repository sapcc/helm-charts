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
        description: Node {{`{{ $labels.node }}`}} is not advertising any prefixes to its BGP neighbor {{`{{ $labels.neighbor }}`}}. Network datapath threatened!
        summary: Node {{`{{ $labels.node }}`}} is not advertising any prefixes to its BGP neighbor {{`{{ $labels.neighbor }}`}}.

    - alert: KubeParrotBgpScrapeMissing
      expr: sum by (instance) (up{job="parrot-metrics"} == 0)
      for: 15m
      labels:
        tier: k8s
        service: kube-parrot
        severity: warning
        context: availability
        playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor.html"
      annotations:
        description: kube-parrot is not running on {{`{{ $labels.instance }}`}}. Check if per-rack DaemonSet selector matches the node rack label.
        summary: kube-parrot is not running on all bare metal nodes. Network datapath threatened!

