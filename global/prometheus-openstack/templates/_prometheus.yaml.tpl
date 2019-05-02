- job_name: 'prometheus-openstack-regions-federation'
  scheme: https
  scrape_interval: 30s
  scrape_timeout: 25s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{__name__=~"^ALERTS$"}'
      - '{__name__=~"up"}'
      - '{__name__=~"^openstack_.+"}'
      - '{__name__=~"^limes_consolidated_.+"}'
      - '{__name__=~"^limes_domain_quota$", resource=~"instances_z.*"}'
      - '{__name__=~"^limes_project_.+$", resource=~"instances_z.*"}'
      - '{__name__=~"^swift_cluster_storage_used_percent_.+"}'
      - '{__name__=~"^openstack_compute_instances_total$"}'
      - '{__name__=~"^blackbox_.+"}'
      - '{__name__=~"^canary_.+"}'
      - '{__name__=~"^datapath_.+"}'
      - '{__name__=~"^elektra_open_inquiry_metrics$"}'

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: prometheus-openstack.(.+).cloud.sap
      replacement: $1
    - action: replace
      target_label: cluster_type
      replacement: controlplane

  static_configs:
    - targets:
{{- range $region := .Values.regionList }}
      - "prometheus-openstack.{{ $region }}.cloud.sap"
{{- end }}
