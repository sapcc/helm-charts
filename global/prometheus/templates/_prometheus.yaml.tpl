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
      - '{__name__=~"^blackbox_.+"}'
      - '{__name__=~"^canary_.+"}'
      - '{__name__=~"^datapath_.+"}'
      - '{__name__=~"^elektra_open_inquiry_metrics$"}'
      - '{__name__=~"^kube_node_.+"}'
      - '{__name__=~"up"}'
      - '{__name__=~"^swift_cluster_storage_used_percent_.+"}'
      - '{__name__=~"^pg_database_size_bytes_gauge_average$"}'
      - '{__name__=~"^probe_(dns|duration|http|success).*"}'
      - '{__name__=~"^limes_consolidated_.+"}'
      - '{__name__=~"^openstack_compute_instances_total$"}'
      - '{__name__=~"^vcenter_vcenter_node_info$"}'
      - '{__name__=~"^vcenter_esx_node_info$"}'
      - 'vice_president_remaining_tokens{region="eu-de-1"}'


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
  honor_labels: true
  params:
    match[]:
    - '{__name__=~"^ALERTS$"}'
    - '{__name__=~"up"}'
  scrape_interval: 30s
  scrape_timeout: 25s
  metrics_path: /federate
  scheme: https
  {{- if .Values.kubernikus.authentication.enabled }}
  tls_config:
    cert_file: /etc/secrets/prometheus_sso.crt
    key_file: /etc/secrets/prometheus_sso.key
  {{- end }}
  static_configs:
  - targets:
{{- range $region := .Values.kubernikus.regions }}
    - "prometheus.kubernikus.{{ $region }}.cloud.sap"
{{- end }}

alerting:
  alertmanagers:
  - scheme: https
    static_configs:
    - targets:
      - "alertmanager.eu-de-1.cloud.sap"
      - "alertmanager.eu-nl-1.cloud.sap"
