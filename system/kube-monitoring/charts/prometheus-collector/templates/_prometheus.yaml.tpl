rule_files:
  - ./*.rules

global:
  scrape_timeout: 55s

scrape_configs:
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

- job_name: 'kube-system/apiserver'
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  scheme: https
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

- job_name: 'kube-system/kubelet'
  scheme: https
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  kubernetes_sd_configs:
  - role: node
  relabel_configs:
  - action: labelmap
    regex: __meta_kubernetes_node_label_(.+)
  - target_label: component
    replacement: kubelet
  - action: replace
    source_labels: [__meta_kubernetes_node_name]
    target_label: instance
  metric_relabel_configs:
  - source_labels: [id]
    regex:  '.+(mount|service)'
    action: drop

- job_name: 'kube-system/node'
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

{{ if and (eq .Capabilities.KubeVersion.Major "1") (ge .Capabilities.KubeVersion.Minor "7") }}
- job_name: 'kubernetes-cadvisors'
  scheme: https
  tls_config:
    ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  kubernetes_sd_configs:
    - role: node
  relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_node_label_(.+)
    - target_label: __address__
      replacement: kubernetes.default:443
    - source_labels: [__meta_kubernetes_node_name]
      regex: (.+)
      target_label: __metrics_path__
      replacement: /api/v1/nodes/${1}:4194/proxy/metrics
{{ end -}}

{{- range $region := .Values.global.regions }}
- job_name: 'blackbox-ingress-{{ $region }}'
  metrics_path: /probe
  params:
    # Look for a HTTP 200 response per default.
    # Can be overwritten by annotating the ingress resource with the expected return codes, e.g. `prometheus.io/probe_code: "4xx"`
    module: [http_2xx]
  scheme: https
  kubernetes_sd_configs:
  - role: ingress
  relabel_configs:
  - source_labels: [__meta_kubernetes_ingress_annotation_prometheus_io_probe]
    action: keep
    regex: true
  # consider prometheus.io/probe_code annotation. mind below regex.
  - source_labels: [__meta_kubernetes_ingress_annotation_prometheus_io_probe_code]
    regex: ^(\d).+
    replacement: http_${1}xx
    target_label: __param_module
  - source_labels: [__meta_kubernetes_ingress_annotation_prometheus_io_probe_module]
    regex: (.+)
    target_label: __param_module
  - source_labels: [__meta_kubernetes_ingress_annotation_prometheus_io_probe_path]
    regex: ^(\/.+)
    target_label: __meta_kubernetes_ingress_path
  - source_labels: [__meta_kubernetes_ingress_scheme,__address__,__meta_kubernetes_ingress_path]
    regex: (.+);(.+);(.+)
    replacement: ${1}://${2}${3}
    target_label: __param_target
  - target_label: __address__
    replacement: prober.{{ $region }}.cloud.sap
  - source_labels: [__param_target]
    target_label: instance
  - action: labelmap
    regex: __meta_kubernetes_ingress_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_ingress_name]
    target_label: ingress_name
  - source_labels: [__param_module]
    target_label: module
  - target_label: region_probed_from
    replacement: {{ $region }}
{{- end }}

{{ $root := .Values }}
{{- if .Values.blackbox_exporter }}
{{- if .Values.blackbox_exporter.static_config }}
{{- range $module, $module_config := .Values.blackbox_exporter.static_config }}
- job_name: 'blackbox-static-targets-{{ $module }}'
  metrics_path: /probe
  params:
    module: [{{ $module }}]
  static_configs:
    - targets:
      {{- range  $module_config.targets }}
      - {{ . }}
      {{- end }}
  scheme: https
  relabel_configs:
  - source_labels: [__address__]
    target_label: __param_target
  - source_labels: [__param_target]
    target_label: instance
  - target_label: __address__
    replacement: prober.{{ $root.global.region }}.cloud.sap
  - source_labels: [__param_module]
    target_label: module
  - target_label: region_probed_from
    replacement: {{ $root.global.region }}
{{ end }}
{{ end }}

{{- if .Values.blackbox_exporter.tcp_probe_targets }}
{{- range $region := .Values.global.regions }}
- job_name: 'blackbox-tcp-{{ $region }}'
  metrics_path: /probe
  scrape_interval: 15s
  params:
    module: [tcp_connect]
  static_configs:
    - targets:
      {{- range $.Values.blackbox_exporter.tcp_probe_targets }}
      - {{ . }}
      {{- end }}
  scheme: https
  relabel_configs:
  - source_labels: [__address__]
    target_label: __param_target
  - source_labels: [__param_target]
    target_label: instance
  - target_label: __address__
    replacement: prober.{{ $region }}.cloud.sap
  - source_labels: [__param_module]
    target_label: module
  - target_label: region_probed_from
    replacement: {{ $region }}
{{- end }}
{{- end }}
{{- end }}

{{- if .Values.global.ipmi_exporter.enabled }}
- job_name: 'ipmi-{{ .Values.global.region }}'
  scrape_interval: 120s
  scrape_timeout: 120s
  file_sd_configs:
      - files :
        - custom_targets/ipmi_targets.json
  metrics_path: /ipmi
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: impi-exporter.{{.Values.global.region}}.{{.Values.global.domain}}:9290
{{- end }}

# Static Targets 
#
- job_name: 'prometheus-collector'
  static_configs:
    - targets: ['localhost:9090']

- job_name: 'static-targets'
  file_sd_configs:
    - files:
      - /etc/prometheus/static_targets.json
