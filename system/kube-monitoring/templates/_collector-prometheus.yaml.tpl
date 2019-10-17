# Scrape config for pods
#
# The relabeling allows the actual pod scrape endpoint to be configured via the
# following annotations:
#
# * `prometheus.io/scrape`: Only scrape pods that have a value of `true`
# * `prometheus.io/path`: If the metrics path is not `/metrics` override this.
# * `prometheus.io/port`: Scrape the pod on the indicated port instead of the default of `9102`.
- job_name: 'pods'
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - action: keep
    source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
    regex: true
  {{- if not (eq .Values.global.region "admin") }}
  - action: keep
    source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_targets]
    regex: .*kubernetes.*
  {{- end }}
  - action: keep
    source_labels: [__meta_kubernetes_pod_container_port_number, __meta_kubernetes_pod_container_port_name, __meta_kubernetes_pod_annotation_prometheus_io_port]
    regex: (9102;.*;.*)|(.*;metrics;.*)|(.*;.*;\d+)
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
    target_label: __metrics_path__
    regex: (.+)
  - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
    target_label: __address__
    regex: ([^:]+)(?::\d+)?;(\d+)
    replacement: ${1}:${2}
  - action: labelmap
    regex: __meta_kubernetes_pod_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_pod_name]
    target_label: kubernetes_pod_name

# Scrape config for pods with an additional port for metrics via `prometheus.io/port_1` annotation.
#
# * `prometheus.io/scrape`: Only scrape pods that have a value of `true`
# * `prometheus.io/path`: If the metrics path is not `/metrics` override this.
# * `prometheus.io/port_1`: Scrape the pod on the indicated port instead of the default of `9102`.
- job_name: 'pods_metric_port_1'
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - action: keep
    source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
    regex: true
  {{- if not (eq .Values.global.region "admin") }}
  - action: keep
    source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_targets]
    regex: .*kubernetes.*
  {{- end }}
  - action: keep
    source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port_1]
    regex: \d+
  - action: keep
    source_labels: [__meta_kubernetes_pod_container_port_number, __meta_kubernetes_pod_container_port_name, __meta_kubernetes_pod_annotation_prometheus_io_port_1]
    regex: (9102;.*;.*)|(.*;metrics;.*)|(.*;.*;\d+)
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
    target_label: __metrics_path__
    regex: (.+)
  - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port_1]
    target_label: __address__
    regex: ([^:]+)(?::\d+)?;(\d+)
    replacement: ${1}:${2}
  - action: labelmap
    regex: __meta_kubernetes_pod_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_pod_name]
    target_label: kubernetes_pod_name

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

- job_name: 'kube-dns'
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

- job_name: 'kubernetes-kubelet'
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

- job_name: 'kubernetes-apiserver'
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  scheme: https
{{- if eq .Values.global.clusterType "controlplane" }}
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - action: keep
    source_labels: [__meta_kubernetes_namespace]
    regex: kube-system
  - action: keep
    source_labels: [__meta_kubernetes_pod_name]
    regex: (kubernetes-master[^\.]+).+
  - target_label: component
    replacement: apiserver
  - action: replace
    source_labels: [__meta_kubernetes_pod_node_name]
    target_label: instance
{{- else }}
  static_configs:
  - targets:
    - $(KUBERNETES_SERVICE_HOST)
  relabel_configs:
    - target_label: component
      replacement: apiserver
{{- end }}
  metric_relabel_configs:
{{ include "prometheus.keep-metrics.metric-relabel-config" .Values.allowedMetrics.kubeAPIServer | indent 2 }}
