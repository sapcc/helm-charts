# vi:syntax=yaml
### General node health ###

groups:
- name: node.alerts
  rules:
  - alert: NodeHostHighCPUUsage
    expr: 100 - (avg by (node) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
    for: 15m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      severity: warning
      context: node
      meta: "High CPU usage on {{`{{ $labels.node }}`}}"
      dashboard: nodes?var-server={{`{{$labels.node}}`}}
    annotations:
      summary: High load on node
      description: "Node {{`{{ $labels.node }}`}} has more than {{`{{ $value }}`}}% CPU load"

  - alert: NodeKernelDeadlock
    expr: kube_node_status_condition{condition="KernelDeadlock", status="true"} == 1
    for: 96h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      severity: info
      context: availability
      meta: "Kernel deadlock on {{`{{ $labels.node }}`}}"
      playbook: docs/support/playbook/k8s_node_safe_rebooting.html
    annotations:
      description: Node kernel has deadlock
      summary: Permanent kernel deadlock on {{`{{ $labels.node }}`}}. Please drain and reboot node

  - alert: NodeDiskPressure
    expr: kube_node_status_condition{condition="DiskPressure",status="true"} == 1
    for: 5m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      severity: warning
      context: node
      meta: "Disk pressure on {{`{{ $labels.node }}`}}"
    annotations:
      description: Insufficient disk space
      summary: Node {{`{{ $labels.node }}`}} under pressure due to insufficient available disk space

  - alert: NodeMemoryPressure
    expr: kube_node_status_condition{condition="MemoryPressure",status="true"} == 1
    for: 5m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      severity: warning
      context: node
      meta: "Memory pressure on {{`{{ $labels.node }}`}}"
    annotations:
      description: Insufficient memory
      summary: Node {{`{{ $labels.node }}`}} under pressure due to insufficient available memory

  - alert: NodeDiskUsagePercentage
    expr: (100 - 100 * sum(node_filesystem_avail_bytes{device!~"tmpfs|by-uuid",fstype=~"xfs|ext"} / node_filesystem_size_bytes{device!~"tmpfs|by-uuid",fstype=~"xfs|ext"}) BY (node,device)) > 85
    for: 5m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      severity: info
      context: node
      meta: "Node disk usage above 85% on {{`{{ $labels.node }}`}} device {{`{{ $labels.device }}`}}"
    annotations: 
      description: "Node disk usage above 85%"
      summary: "Disk usage on target {{`{{ $labels.node }}`}} at {{`{{ $value }}`}}%"

  ### Network health ###

  - alert: NodeHighNumberOfOpenConnections
    expr: node_netstat_Tcp_CurrEstab > 20000
    for: 15m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      severity: warning
      context: availability
      meta: "{{`{{ $labels.node }}`}}"
      dashboard: "nodes?var-server={{`{{ $labels.node }}`}}"
    annotations:
      description: High number of open TCP connections
      summary: The node {{`{{ $labels.node }}`}} has more than 20000 active TCP connections. The maximally possible amount is 32768 connections

  - alert: NodeHighRiseOfOpenConnections
    expr: predict_linear(node_netstat_Tcp_CurrEstab[20m], 3600) > 32768
    for: 15m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      severity: warning
      context: availability
      meta: "{{`{{ $labels.node }}"
      dashboard: "nodes?var-server={{$labels.node}}`}}"
      playbook: "docs/support/playbook/kubernetes/k8s_high_tcp_connections.html"
    annotations:
      description: High number of open TCP connections
      summary: The node {{`{{ $labels.node }}`}} will likely reach 32768 active TCP connections within the next hour. If that happens, it cannot accept any new connections

  - alert: NodeContainerOOMKilled
    expr: sum by (node) (changes(node_vmstat_oom_kill[24h])) > 3
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      severity: info
      context: memory
    annotations:
      description: More than 3 OOM killed pods on a node within 24h
      summary: More than 3 OOM killed pods on node {{`{{ $labels.node }}`}} within 24h

  - alert: NodeHighNumberOfThreads
    expr: node_processes_threads > 31000
    for: 1h
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      severity: critical
      context: threads
      meta: "Very high number of threads on {{`{{ $labels.node }}`}}. Forking problems are imminent."
      playbook: "docs/support/playbook/kubernetes/k8s_high_threads.html"
    annotations:
      description: "Very high number of threads on {{`{{ $labels.node }}`}}. Forking problems are imminent."
      summary: Very high number of threads

  ### Bonding health ###

  - alert: NodeBondDegradedNetwork
    expr: sum(node_bonding_active{master="bond1",node=~"[^storage].*cloud.sap"}) by (master, node) < 2
    for: 15m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      severity: info 
      context: bond 
      meta: "{{`{{ $labels.node }}`}}"
      playbook: "docs/support/playbook/kubernetes/k8s_bond_degraded.html"
    annotations:
      description: Bond {{`{{ $labels.master }}`}} on {{`{{ $labels.node }}`}} is degraded.
      summary: Bond {{`{{ $labels.master }}`}} is degraded. This bond isn't used but this situation could cause problems on reboot.

  - alert: NodeBondDegradedNetwork
    expr: sum(node_bonding_active{master="bond1",node=~"network.*cloud.sap"}) by (master, node) == 1
    for: 15m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      severity: critical 
      context: bond 
      meta: "{{`{{ $labels.node }}`}}"
      playbook: "docs/support/playbook/kubernetes/k8s_bond_degraded.html"
    annotations:
      description: Bond {{`{{ $labels.master }}`}} on {{`{{ $labels.node }}`}} is degraded. Network datapath threatened!
      summary: Bond {{`{{ $labels.master }}`}} is degraded. Switch failover will cause this node to be disconneted. Network datapath is not HA! Incidents on the other network node will take out the whole region!

  - alert: NodeBondDegradedMain
    expr: sum(node_bonding_active{master="bond2",node=~".*cloud.sap"}) by (master, node) < 2
    for: 15m
    labels:
      tier: {{ required ".Values.tier missing" .Values.tier }}
      service: node
      severity: warning 
      context: bond 
      meta: "{{`{{ $labels.node }}`}}"
      playbook: "docs/support/playbook/kubernetes/k8s_bond_degraded.html"
    annotations:
      description: Bond {{`{{ $labels.master }}`}} on {{`{{ $labels.node }}`}} is degraded. Imminent network outage for this node.
      summary: Bond {{`{{ $labels.master }}`}} is degraded. Network connectivity is not HA. Switch failover and ACI upgrades will cause an outage!
