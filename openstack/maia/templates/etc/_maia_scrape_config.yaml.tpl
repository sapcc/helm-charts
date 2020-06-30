- job_name: 'maia-exporters'
  scrape_interval: 1m
  scrape_timeout: 55s
  kubernetes_sd_configs:
    - role: endpoints
  relabel_configs:
    # filter by maia scrape annotation
    - action: keep
      source_labels: [__meta_kubernetes_service_annotation_maia_io_scrape]
      regex: true
    - action: keep
      source_labels: [__meta_kubernetes_pod_container_port_number, __meta_kubernetes_pod_container_port_name, __meta_kubernetes_service_annotation_prometheus_io_port]
      regex: (9102;.*;.*)|(.*;metrics;.*)|(.*;.*;\d+)
    # support existing prometheus annotations (same configuration as everywhere else)
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
      target_label: __scheme__
      regex: (https?)
    - source_labels: [__meta_kubernetes_service_annotation_maia_io_scheme]
      target_label: __scheme__
      regex: (https?)
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
      target_label: __metrics_path__
      regex: (.+)
    - source_labels: [__meta_kubernetes_service_annotation_maia_io_path]
      target_label: __metrics_path__
      regex: (.+)
    - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
      target_label: __address__
      regex: ([^:]+)(?::\d+)?;(\d+)
      replacement: $1:$2
    - source_labels: [__address__, __meta_kubernetes_service_annotation_maia_io_port]
      target_label: __address__
      regex: ([^:]+)(?::\d+)?;(\d+)
      replacement: $1:$2
    - action: labelmap
      regex: __meta_kubernetes_service_label_(.+)
    - source_labels: [__meta_kubernetes_namespace]
      target_label: kubernetes_namespace
    - source_labels: [__meta_kubernetes_service_name]
      target_label: kubernetes_name
    # support injection of custom parameters
    - action: labelmap
      replacement: __param_$1
      regex: __meta_kubernetes_service_annotation_maia_io_scrape_param_(.+)

  metric_relabel_configs:
    - action: drop
      source_labels: [vmware_name]
      regex: c_blackbox.*|c_regression.*
    - action: labeldrop
      regex: "instance|job"
    - source_labels: [ltmVirtualServStatName]
      target_label: project_id
      regex: /Project_(.*)/Project_.*
    - source_labels: [ltmVirtualServStatName]
      target_label: lb_id
      regex: /Project_.*/Project_(.*)

# expose tenant-specific metrics collected by kube-system monitoring
#
# FIXME: This is a cross-dependency between different chains of Prometheus
# instances which we want to avoid going forward. The pods supplying these
# metrics should be scraped by Maia directly.
#
# Since some of these metrics are already aggregated (e.g. the ones for
# Castellum), it may be necessary to add a maia-prometheus-collector that
# performs the aggregations before metrics are pulled into this Prometheus.
#- job_name: 'kube-system'
#  static_configs:
#    - targets: ['prometheus-collector.kube-monitoring:9090']
#  metric_relabel_configs:
#    - regex: "instance|job|kubernetes_namespace|kubernetes_pod_name|kubernetes_name|pod_template_hash|exported_instance|exported_job|type|name|component|app|system"
#      action: labeldrop
#  metrics_path: '/federate'
#  params:
#    'match[]':
#      # import any tenant-specific metric, except for those which already have been imported
#      - '{__name__=~"^castellum_aggregated_.+",project_id!=""}'
#      - '{__name__=~"^openstack_.+",project_id!=""}'
#      - '{__name__=~"^limes_(project|domain)_(quota|usage)"}'

- job_name: 'prometheus-openstack'
  scrape_interval: 1m
  scrape_timeout: 55s
  static_configs:
    - targets: ['prometheus-openstack.prometheus-openstack:9090']
  metric_relabel_configs:
    - regex: "instance|job|kubernetes_namespace|kubernetes_pod_name|kubernetes_name|pod_template_hash|exported_instance|exported_job|type|name|component|app|system"
      action: labeldrop
  metrics_path: '/federate'
  params:
    'match[]':
      # import any tenant-specific metric, except for those which already have been imported
      - '{__name__=~"^castellum_aggregated_.+",project_id!=""}'
      - '{__name__=~"^openstack_.+",project_id!=""}'
      - '{__name__=~"^limes_(project|domain)_(quota|usage)"}'

- job_name: 'prometheus-infra-collector'
  scrape_interval: 1m
  scrape_timeout: 55s
  static_configs:
    - targets: ['prometheus-infra-collector.infra-monitoring:9090']
  metric_relabel_configs:
    - regex: "instance|job|kubernetes_namespace|kubernetes_pod_name|kubernetes_name|pod_template_hash|exported_instance|exported_job|type|name|component|app|system"
      action: labeldrop
    - action: drop
      source_labels: [vmware_name]
      regex: c_blackbox.*|c_regression.*
    - action: drop
      source_labels: [__name__]
      regex: netapp_volume_saved_.*
    - source_labels: [ltmVirtualServStatName]
      target_label: project_id
      regex: /Project_(.*)/Project_.*
    - source_labels: [ltmVirtualServStatName]
      target_label: lb_id
      regex: /Project_.*/Project_(.*)
    - source_labels: [__name__]
      target_label: __name__
      regex: netapp_volume_(.*)
      replacement: openstack_manila_share_${1}

  metrics_path: '/federate'
  params:
    'match[]':
      # import any tenant-specific metric, except for those which already have been imported
      - '{__name__=~"^snmp_f5_.+"}'
      - '{__name__=~"^vcenter_cpu_.+"}'
      - '{__name__=~"^vcenter_disk_.+"}'
      - '{__name__=~"^vcenter_mem_.+"}'
      - '{__name__=~"^vcenter_net_.+"}'
      - '{__name__=~"^vcenter_virtualDisk_.+"}'
      - '{__name__=~"^netapp_capacity_.+"}'
      - '{__name__=~"^netapp_volume_.+", app="netapp-capacity-exporter-manila"}'
      - '{__name__=~"^openstack_manila_share_.+", project_id!=""}'
