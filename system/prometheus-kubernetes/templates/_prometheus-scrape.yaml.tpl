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
  - source_labels: [__metrics_path__]
    target_label: metrics_path

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
  - source_labels: [__metrics_path__]
    target_label: metrics_path

# enabling linkerd scrapes
- job_name: 'linkerd-controller'
  kubernetes_sd_configs:
  - role: pod
    namespaces:
      names:
      - 'linkerd'
  relabel_configs:
  - source_labels:
    - __meta_kubernetes_pod_container_port_name
    action: keep
    regex: admin-http
  - source_labels: [__meta_kubernetes_pod_container_name]
    action: replace
    target_label: component

- job_name: 'linkerd-service-mirror'
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - source_labels:
    - __meta_kubernetes_pod_label_linkerd_io_control_plane_component
    - __meta_kubernetes_pod_container_port_name
    action: keep
    regex: linkerd-service-mirror;admin-http$
  - source_labels: [__meta_kubernetes_pod_container_name]
    action: replace
    target_label: component

- job_name: 'linkerd-proxy'
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - source_labels:
    - __meta_kubernetes_pod_container_name
    - __meta_kubernetes_pod_container_port_name
    - __meta_kubernetes_pod_label_linkerd_io_control_plane_ns
    action: keep
    regex: ^{{default .Values.proxyContainerName "linkerd-proxy" .Values.proxyContainerName}};linkerd-admin;linkerd$
  - source_labels: [__meta_kubernetes_namespace]
    action: replace
    target_label: namespace
  - source_labels: [__meta_kubernetes_pod_name]
    action: replace
    target_label: pod
  # special case k8s' "job" label, to not interfere with prometheus' "job"
  # label
  # __meta_kubernetes_pod_label_linkerd_io_proxy_job=foo =>
  # k8s_job=foo
  - source_labels: [__meta_kubernetes_pod_label_linkerd_io_proxy_job]
    action: replace
    target_label: k8s_job
  # drop __meta_kubernetes_pod_label_linkerd_io_proxy_job
  - action: labeldrop
    regex: __meta_kubernetes_pod_label_linkerd_io_proxy_job
  # __meta_kubernetes_pod_label_linkerd_io_proxy_deployment=foo =>
  # deployment=foo
  - action: labelmap
    regex: __meta_kubernetes_pod_label_linkerd_io_proxy_(.+)
  # drop all labels that we just made copies of in the previous labelmap
  - action: labeldrop
    regex: __meta_kubernetes_pod_label_linkerd_io_proxy_(.+)
  # __meta_kubernetes_pod_label_linkerd_io_foo=bar =>
  # foo=bar
  - action: labelmap
    regex: __meta_kubernetes_pod_label_linkerd_io_(.+)
  # Copy all pod labels to tmp labels
  - action: labelmap
    regex: __meta_kubernetes_pod_label_(.+)
    replacement: __tmp_pod_label_$1
  # Take `linkerd_io_` prefixed labels and copy them without the prefix
  - action: labelmap
    regex: __tmp_pod_label_linkerd_io_(.+)
    replacement:  __tmp_pod_label_$1
  # Drop the `linkerd_io_` originals
  - action: labeldrop
    regex: __tmp_pod_label_linkerd_io_(.+)
  # Copy tmp labels into real labels
  - action: labelmap
    regex: __tmp_pod_label_(.+)
