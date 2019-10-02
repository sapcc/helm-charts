- job_name: 'kube-system/etcd'
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - action: keep
    source_labels: [__meta_kubernetes_namespace]
    regex: kube-system
  - action: keep
    source_labels: [__meta_kubernetes_pod_name]
    regex: (etcd-[^\.]+).+
  - source_labels: [__address__]
    target_label: __address__
    regex: ([^:]+)(:\d+)?
    replacement: ${1}:2379
  - target_label: component
    replacement: etcd
  - action: replace
    source_labels: [__meta_kubernetes_pod_node_name]
    target_label: instance

- job_name: 'kube-system/controller-manager'
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - action: keep
    source_labels: [__meta_kubernetes_namespace]
    regex: kube-system
  - action: keep
    source_labels: [__meta_kubernetes_pod_name]
    regex: (kubernetes-master[^\.]+).+
  - source_labels: [__address__]
    action: replace
    regex: ([^:]+)(:\d+)?
    replacement: ${1}:10252
    target_label: __address__
  - target_label: component
    replacement: controller-manager
  - action: replace
    source_labels: [__meta_kubernetes_pod_node_name]
    target_label: instance

- job_name: 'kube-system/scheduler'
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - action: keep
    source_labels: [__meta_kubernetes_namespace]
    regex: kube-system
  - action: keep
    source_labels: [__meta_kubernetes_pod_name]
    regex: (kubernetes-master[^\.]+).+
  - source_labels: [__address__]
    replacement: ${1}:10251
    regex: ([^:]+)(:\d+)?
    target_label: __address__
  - target_label: component
    replacement: scheduler
  - action: replace
    source_labels: [__meta_kubernetes_pod_node_name]
    target_label: instance

- job_name: 'kube-system/dnsmasq'
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - action: keep
    source_labels: [__meta_kubernetes_namespace]
    regex: kube-system
  - action: keep
    source_labels: [__meta_kubernetes_pod_name]
    regex: (kube-dns[^\.]+).+
  - source_labels: [__address__]
    target_label: __address__
    regex: ([^:]+)(:\d+)?
    replacement: ${1}:10054
  - target_label: component
    replacement: dnsmasq
  - action: replace
    source_labels: [__meta_kubernetes_pod_node_name]
    target_label: instance

- job_name: 'kube-system/dns'
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - action: keep
    source_labels: [__meta_kubernetes_namespace]
    regex: kube-system
  - action: keep
    source_labels: [__meta_kubernetes_pod_name]
    regex: (kube-dns[^\.]+).+
  - source_labels: [__address__]
    target_label: __address__
    regex: ([^:]+)(:\d+)?
    replacement: ${1}:10055
  - target_label: component
    replacement: dns
  - action: replace
    source_labels: [__meta_kubernetes_pod_node_name]
    target_label: instance

- job_name: 'prometheus-node-exporters'
  kubernetes_sd_configs:
  - role: node
  relabel_configs:
  - action: labelmap
    regex: __meta_kubernetes_node_label_(.+)
  - target_label: component
    replacement: node
  - action: replace
    source_labels: [__meta_kubernetes_node_name]
    target_label: instance
  - source_labels: [__address__]
    target_label: __address__
    regex: ([^:]+)(:\d+)?
    replacement: ${1}:9100
  - source_labels: [mountpoint]
    target_label: mountpoint
    regex: '(/host/)(.+)'
    replacement: '${1}'

- job_name: 'kube-system/ntp'
  kubernetes_sd_configs:
  - role: node
  relabel_configs:
  - action: labelmap
    regex: __meta_kubernetes_node_label_(.+)
  - target_label: component
    replacement: node
  - action: replace
    source_labels: [__meta_kubernetes_node_name]
    target_label: instance
  - source_labels: [__address__]
    target_label: __address__
    regex: ([^:]+)(:\d+)?
    replacement: ${1}:9101

- job_name: 'kube-system/kubelet'
  scheme: https
  kubernetes_sd_configs:
  - role: node
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    insecure_skip_verify: true
  relabel_configs:
  - separator: ;
    regex: __meta_kubernetes_node_label_(.+)
    replacement: $1
    action: labelmap
  - separator: ;
    regex: (.*)
    target_label: component
    replacement: kubelet
    action: replace
  - source_labels: [__meta_kubernetes_node_name]
    separator: ;
    regex: (.*)
    target_label: instance
    replacement: $1
    action: replace
  metric_relabel_configs:
    - source_labels: [ id ]
      action: replace
      regex: ^/system\.slice/(.+)\.service$
      target_label: systemd_service_name
      replacement: '${1}'
    - source_labels: [ id ]
      action: replace
      regex: ^/system\.slice/(.+)\.service$
      target_label: container_name
      replacement: '${1}'
{{ include "prometheus.keep-metrics.metric-relabel-config" .Values.allowedMetrics.kubelet | indent 4 }}
    - source_labels:
      - container_name
      - __name__
      # The system container POD is used for networking.
      regex: POD;({{ .Values.allowedMetrics.kubelet | join "|" }})
      action: drop

- job_name: 'kubernetes-cadvisors'
  scheme: https
  metrics_path: /metrics/cadvisor
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    insecure_skip_verify: true
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  kubernetes_sd_configs:
    - role: node
  relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_node_label_(.+)
  metric_relabel_configs:
    - source_labels: [ id ]
      action: replace
      regex: ^/system\.slice/(.+)\.service$
      target_label: systemd_service_name
      replacement: '${1}'
    - source_labels: [ id ]
      action: replace
      regex: ^/system\.slice/(.+)\.service$
      target_label: container_name
      replacement: '${1}'
{{ include "prometheus.keep-metrics.metric-relabel-config" .Values.allowedMetrics.cAdvisor | indent 4 }}
    - source_labels:
      - container_name
      - __name__
      # The system container POD is used for networking.
      regex: POD;({{ without .Values.allowedMetrics.cAdvisor "container_network_receive_bytes_total" "container_network_transmit_bytes_total" | join "|" }})
      action: drop
    - source_labels: [ container_name ]
      regex: ^$
      action: drop
    - regex: ^id$
      action: labeldrop

- job_name: 'kube-system/apiserver'
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  scheme: https

  static_configs:
  - targets:
    - $(KUBERNETES_SERVICE_HOST)
  relabel_configs:
    - target_label: component
      replacement: apiserver

  metric_relabel_configs:
{{ include "prometheus.keep-metrics.metric-relabel-config" .Values.allowedMetrics.kubeAPIServer | indent 2 }}
