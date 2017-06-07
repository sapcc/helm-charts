### General node health ###

ALERT KubernetesHostHighCPUUsage
  IF avg(irate(node_cpu{mode="idle"}[5m])) by(instance, region) < 0.2
  FOR 3m
  LABELS {
    tier = "kubernetes",
    service   = "node",
    severity  = "warning",
    context   = "availability",
    dashboard = "kubernetes-node?var-server={{`{{$labels.instance}}`}}"
  }
  ANNOTATIONS {
    summary = "High load on node",
    description = "The node {{`{{ $labels.instance }}`}} has more than 80% CPU load.",
  }

ALERT KubernetesNodeClockDrift
  IF abs(ntp_drift_seconds) > 0.3
  FOR 10m
  LABELS {
    tier = "kubernetes",
    service = "node",
    severity = "info",
    context = "availability",
    dashboard = "kubernetes-node?var-server={{`{{$labels.instance}}`}}"
  }
  ANNOTATIONS {
    summary = "High NTP drift",
    description = "The clock on node {{`{{ $labels.instance }}`}} is more than 300ms apart from its NTP server. This can cause service degradation in Swift.",
  }

ALERT KubernetesNodeKernelDeadlock
  IF kube_node_status_kernel_deadlock{condition="true"} == 1
  FOR 48h
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "critical",
    context = "availability",
    {{ if .Values.ops_docu_url -}}
    playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/k8s_node_safe_rebooting.html",
    {{- end }}
  }
  ANNOTATIONS {
    summary = "Node kernel has deadlock",
    description = "Permanent kernel deadlock on {{`{{$labels.node}}`}}. Please drain and reboot node.",
  }

### Network health ###

ALERT KubernetesNodeHighNumberOfOpenConnections
  IF node_netstat_Tcp_CurrEstab > 20000
  FOR 15m
  LABELS {
    tier = "kubernetes",
    service = "node",
    severity = "warning",
    context = "availability",
    dashboard = "kubernetes-node?var-server={{`{{$labels.instance}}`}}",
    {{ if .Values.ops_docu_url -}}
    playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/k8s_high_tcp_connections.html",
    {{- end }}
  }
  ANNOTATIONS {
    summary = "High number of open TCP connections",
    description = "The node {{`{{ $labels.instance }}`}} has more than 20000 active TCP connections. The maximally possible amount is 32768 connections.",
  }

ALERT KubernetesNodeHighRiseOfOpenConnections
  IF predict_linear(node_netstat_Tcp_CurrEstab[20m], 3600) > 32768
  FOR 15m
  LABELS {
    tier = "kubernetes",
    service = "node",
    severity = "critical",
    context = "availability",
    dashboard = "kubernetes-node?var-server={{`{{$labels.instance}}`}}",
    {{ if .Values.ops_docu_url -}}
    playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/k8s_high_tcp_connections.html",
    {{- end }}
  }
  ANNOTATIONS {
    summary = "High number of open TCP connections",
    description = "The node {{`{{ $labels.instance }}`}} will likely reach 32768 active TCP connections within the next hour. If that happens, it cannot accept any new connections.",
  }
