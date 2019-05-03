# Scrape config for service endpoints.
#
# The relabeling allows the actual service scrape endpoint to be configured
# via the following annotations:
#
# * `prometheus.io/scrape`: Only scrape services that have a value of `true`
# * `prometheus.io/scheme`: If the metrics endpoint is secured then you will need
# to set this to `https` & most likely set the `tls_config` of the scrape config.
# * `prometheus.io/path`: If the metrics path is not `/metrics` override this.
# * `prometheus.io/port`: If the metrics are exposed on a different port to the
# service then set this appropriately.
- job_name: 'endpoints'
  kubernetes_sd_configs:
  - role: endpoints
  relabel_configs:
  - action: keep
    source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
    regex: true
  - action: keep
    source_labels: [__meta_kubernetes_service_annotation_prometheus_io_targets]
    regex: infra-prometheus
  - action: keep
    source_labels: [__meta_kubernetes_pod_container_port_number, __meta_kubernetes_pod_container_port_name, __meta_kubernetes_service_annotation_prometheus_io_port]
    regex: (9102;.*;.*)|(.*;metrics;.*)|(.*;.*;\d+)
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
    target_label: __scheme__
    regex: (https?)
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
    target_label: __metrics_path__
    regex: (.+)
  - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
    target_label: __address__
    regex: ([^:]+)(?::\d+);(\d+)
    replacement: $1:$2
  - action: labelmap
    regex: __meta_kubernetes_service_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_service_name]
    target_label: kubernetes_name
  # support injection of custom parameters. used by snmp exporter.
  - action: labelmap
    replacement: __param_$1
    regex: __meta_kubernetes_service_annotation_prometheus_io_scrape_param_(.+)
  metric_relabel_configs:
  - source_labels: [component]
    regex: 'snmp-exporter-(\w*-\w*-\w*)-(\S*)'
    replacement: '$1'
    target_label: availability_zone
  - source_labels: [component]
    regex: 'snmp-exporter-(\w*-\w*-\w*)-(\S*)'
    replacement: '$2'
    target_label: device
  - source_labels: [component]
    regex: 'snmp-exporter-(.+)'
    replacement: '$1'
    target_label: devicename
  - source_labels: [component, cluster]
    separator: ;
    regex: elasticsearch-exporter-(.+);(.+)
    target_label: elastic_cluster
    replacement: $2
    action: replace
  - regex: 'cluster'
    action: labeldrop

# Scrape config for endpoints with an additional port for metrics via `prometheus.io/port_1` annotation.
#
# * `prometheus.io/scrape`: Only scrape pods that have a value of `true`
# * `prometheus.io/path`: If the metrics path is not `/metrics` override this.
# * `prometheus.io/port_1`: Scrape the pod on the indicated port instead of the default of `9102`.
- job_name: 'endpoints_metric_port_1'
  kubernetes_sd_configs:
  - role: endpoints
  relabel_configs:
  - action: keep
    source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
    regex: true
  - action: keep
    source_labels: [__meta_kubernetes_service_annotation_prometheus_io_targets]
    regex: infra-prometheus
  - action: keep
    source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port_1]
    regex: \d+
  - action: keep
    source_labels: [__meta_kubernetes_pod_container_port_number, __meta_kubernetes_pod_container_port_name, __meta_kubernetes_service_annotation_prometheus_io_port_1]
    regex: (9102;.*;.*)|(.*;metrics;.*)|(.*;.*;\d+)
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
    target_label: __scheme__
    regex: (https?)
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
    target_label: __metrics_path__
    regex: (.+)
  - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port_1]
    target_label: __address__
    regex: ([^:]+)(?::\d+);(\d+)
    replacement: $1:$2
  - action: labelmap
    regex: __meta_kubernetes_service_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_service_name]
    target_label: kubernetes_name

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
  - action: keep
    source_labels: [__meta_kubernetes_service_annotation_prometheus_io_targets]
    regex: infra-prometheus
  - action: keep
    source_labels: [__meta_kubernetes_pod_container_port_number, __meta_kubernetes_pod_container_port_name, __meta_kubernetes_pod_annotation_prometheus_io_port]
    regex: (9102;.*;.*)|(.*;metrics;.*)|(.*;.*;\d+)
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
    target_label: __metrics_path__
    regex: (.+)
  - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
    target_label: __address__
    regex: ([^:]+)(?::\d+);(\d+)
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
  - action: keep
    source_labels: [__meta_kubernetes_service_annotation_prometheus_io_targets]
    regex: infra-prometheus
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
    regex: ([^:]+)(?::\d+);(\d+)
    replacement: ${1}:${2}
  - action: labelmap
    regex: __meta_kubernetes_pod_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_pod_name]
    target_label: kubernetes_pod_name

- job_name: 'snmp-exporter-arista'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/snmp-exporter-targets/arista.json
  metrics_path: /snmp
  params:
      module: [arista]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: target
    - target_label: __address__
      replacement: snmp-exporter.{{ .Values.global.region }}.{{ .Values.global.domain }}
    - target_label: region
      replacement: {{ .Values.global.region }}

- job_name: 'snmp-exporter-asa'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/snmp-exporter-targets/asa.json
  metrics_path: /snmp
  params:
      module: [asa]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter.{{ .Values.global.region }}.{{ .Values.global.domain }}
    - target_label: region
      replacement: {{ .Values.global.region }}

- job_name: 'snmp-exporter-asr'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/snmp-exporter-targets/asr.json
  metrics_path: /snmp
  params:
      module: [asr]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter.{{ .Values.global.region }}.{{ .Values.global.domain }}
    - target_label: region
      replacement: {{ .Values.global.region }}

- job_name: 'snmp-exporter-asr04'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/snmp-exporter-targets/asr04.json
  metrics_path: /snmp
  params:
      module: [asr04]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter.{{ .Values.global.region }}.{{ .Values.global.domain }}
    - target_label: region
      replacement: {{ .Values.global.region }}

- job_name: 'snmp-exporter-f5'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/snmp-exporter-targets/f5.json
  metrics_path: /snmp
  params:
      module: [f5]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter.{{ .Values.global.region }}.{{ .Values.global.domain }}
    - target_label: region
      replacement: {{ .Values.global.region }}

- job_name: 'snmp-exporter-n7k'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/snmp-exporter-targets/n7k.json
  metrics_path: /snmp
  params:
      module: [n7k]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter.{{ .Values.global.region }}.{{ .Values.global.domain }}
    - target_label: region
      replacement: {{ .Values.global.region }}