groups:
- name: kube-parrot.alerts
  rules:

    ### Kube Parrot ###

    - alert: KubeParrotBgpNeighborSessionDown
      expr: sum by (node) (kube_parrot_bgp_neighbor_session_status{status="established"}) < {{ .Values.bgpNeighborCount }}
      for: 30m
      labels:
        tier: k8s
        service: kube-parrot
        severity: warning
        context: availability
        support_group: containers
        playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor"
      annotations:
        description: Node {{`{{ $labels.node }}`}} has less than {{ .Values.bgpNeighborCount }} BGP neighbors. BGP peer {{`{{ $labels.neighbor }}`}} is not established. Network datapath threatened! Switch upgrades or misconfiguration?
        summary: Node {{`{{ $labels.node }}`}} has less than {{ .Values.bgpNeighborCount }} BGP neighbors.

    - alert: KubeParrotBgpNeighborSessionAllDown
      expr: sum by (node) (kube_parrot_bgp_neighbor_session_status{status="established"}) == 0
      for: 10m
      labels:
        tier: k8s
        service: kube-parrot
        severity: critical
        context: availability
        support_group: containers
        playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor"
      annotations:
        description: Node {{`{{ $labels.node }}`}} has no BGP neighbors. Network datapath is down! Switch upgrades or misconfiguration?
        summary: Node {{`{{ $labels.node }}`}} has no BGP neighbors.

    - alert: KubeParrotBgpNeighborMissingRouteAdvertisement
      expr: sum by (node,neighbor) (kube_parrot_bgp_neighbor_advertised_route_count_total) < 1
      for: 30m
      labels:
        tier: k8s
        service: kube-parrot
        severity: warning
        context: availability
        support_group: containers
        playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor"
      annotations:
        description: Node {{`{{ $labels.node }}`}} is not advertising any prefixes to its BGP neighbor {{`{{ $labels.neighbor }}`}}. Network datapath threatened! Switch upgrades or misconfiguration?
        summary: Node {{`{{ $labels.node }}`}} is not advertising any prefixes to its BGP neighbor {{`{{ $labels.neighbor }}`}}.

    - alert: KubeParrotBgpNeighborAllMissingRouteAdvertisement
      expr: sum by (node) (kube_parrot_bgp_neighbor_advertised_route_count_total) < 1
      for: 30m
      labels:
        tier: k8s
        service: kube-parrot
        severity: critical
        context: availability
        support_group: containers
        playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor"
      annotations:
        description: Node {{`{{ $labels.node }}`}} is not advertising any prefixes to its BGP neighbors. Network datapath is down! Switch upgrades or misconfiguration?
        summary: Node {{`{{ $labels.node }}`}} is not advertising any prefixes to its BGP neighbors.

    - alert: KubeParrotBgpScrapeMissing
      expr: count(up{job="kubernetes-kubelet"} == 1) > count(up{job="parrot-metrics"} == 1)
      for: 15m
      labels:
        tier: k8s
        service: kube-parrot
        severity: warning
        context: availability
        support_group: containers
        playbook: "docs/support/playbook/kubernetes/k8s_node_bgp_neighbor"
      annotations:
        description: kube-parrot is not running on all nodes that are Ready.
        summary: kube-parrot is not running on all bare metal nodes that are Ready. Network datapath threatened!

