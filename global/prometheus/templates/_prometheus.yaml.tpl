rule_files:
  - ./*.rules
  - ./*.alerts

scrape_configs:
- job_name: 'prometheus-global'
  static_configs:
    - targets: ['localhost:9090']

- job_name: 'prometheus-regions-federation'
  scheme: https
  scrape_interval: 30s
  scrape_timeout: 25s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{__name__=~"^ALERTS$"}'
      - '{__name__=~"^alertmanager_.+"}'
      - '{__name__=~"^blackbox_.+"}'
      - '{__name__=~"^canary_.+"}'
      - '{__name__=~"^datapath_.+"}'
      - '{__name__=~"^elektra_open_inquiry_metrics$"}'
      - '{__name__=~"^kube_node_.+"}'
      - '{__name__=~"^snmp_asr_.*"}'
      - '{__name__=~"^snmp_f5_sysGlobalHostSwapUsedKb"}'
      - '{__name__=~"^snmp_f5_sysGlobalHostSwapTotalKb"}'
      - '{__name__=~"^snmp_f5_sysGlobalTmmStatMemoryUsedKb"}'
      - '{__name__=~"^snmp_f5_sysGlobalTmmStatMemoryTotalKb"}'
      - '{__name__=~"^snmp_f5_sysGlobalHostOtherMemUsedKb"}'
      - '{__name__=~"^snmp_f5_sysGlobalHostOtherMemTotalKb"}'
      - '{__name__=~"^snmp_f5_sysHostMemoryUsedKb"}'
      - '{__name__=~"^snmp_f5_sysHostMemoryTotalKb"}'
      - '{__name__=~"^node_cpu_seconds_total",mode="idle"}'
      - '{__name__=~"^node_memory_MemTotal_bytes$",instance=~".+cloud.sap"}'
      - '{__name__=~"^node_memory_MemFree_bytes$",instance=~".+cloud.sap"}'
      - '{__name__=~"^node_memory_Cached_bytes$",instance=~".+cloud.sap"}'
      - '{__name__=~"^node_memory_Buffers_bytes$",instance=~".+cloud.sap"}'
      - '{__name__=~"^node_memory_Slab_bytes$",instance=~".+cloud.sap"}'
      - '{__name__=~"^kube_pod_container_resource_requests_memory_bytes$",node=~".+cloud.sap"}'
      - '{__name__=~"^kube_pod_container_resource_requests_cpu_cores$",node=~".+cloud.sap"}'
      - '{__name__=~"^kube_node_status_capacity$",node=~".+cloud.sap"}'
      - '{__name__=~"^ipmi_sensor_state$",job=~"baremetal/ironic"}'
      - '{__name__=~"up"}'
      - '{__name__=~"^swift_cluster_storage_used_percent_.+"}'
      - '{__name__=~"^openstack_ironic_nodes_.+"}'
      - '{__name__=~"^openstack_ironic_leftover_ports$"}'
      - '{__name__=~"^pg_database_size_bytes_gauge_average$"}'
      - '{__name__=~"^probe_(dns|duration|http|success).*"}'
      - '{__name__=~"^limes_consolidated_.+"}'
      - '{__name__=~"^limes_domain_quota$", resource=~"instances_z.*"}'
      - '{__name__=~"^limes_project_.+$", resource=~"instances_z.*"}'
      - '{__name__=~"^openstack_compute_instances_total$"}'
      - '{__name__=~"^vcenter_vcenter_node_info$"}'
      - '{__name__=~"^vcenter_esx_node_info$"}'
      - '{__name__=~"^vice_president_token_count_remaining$"}'

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: prometheus.(.+).cloud.sap
      replacement: $1

  static_configs:
    - targets:
{{- range $region := .Values.regions }}
      - "prometheus.{{ $region }}.cloud.sap"
{{- end }}

- job_name: 'prometheus-collector-regions-federation'
  scheme: https
  scrape_interval: 30s
  scrape_timeout: 25s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - 'up{job="prometheus-collector"}'

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: prometheus-collector.(.+).cloud.sap
      replacement: $1

  static_configs:
    - targets:
{{- range $region := .Values.regions }}
      - "prometheus-collector.{{ $region }}.cloud.sap"
{{- end }}

- job_name: prometheus-kubernikus-regions-federation
  scrape_interval: 30s
  scrape_timeout: 25s
  scheme: https

  honor_labels: true
  metrics_path: /federate

  params:
    match[]:
    - '{__name__=~"^ALERTS$"}'
    - '{__name__=~"^kubernikus_kluster_status_phase"}'
    - '{__name__=~"up"}'

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: prometheus.kubernikus.(.+).cloud.sap
      replacement: k-$1

  {{- if .Values.kubernikus.authentication.enabled }}
  tls_config:
    cert_file: /etc/secrets/prometheus_sso.crt
    key_file: /etc/secrets/prometheus_sso.key
  {{- end }}

  static_configs:
  - targets:
{{- range $region := .Values.regions }}
{{- if ne $region "admin" }}
    - "prometheus.kubernikus.{{ $region }}.cloud.sap"
{{- end }}
{{- end }}

{{- if .Values.alerting.enabled }}
alerting:
  alertmanagers:
  - scheme: https
    static_configs:
    - targets:
      - "alertmanager.eu-de-1.cloud.sap"
      - "alertmanager.eu-nl-1.cloud.sap"
{{- end }}
