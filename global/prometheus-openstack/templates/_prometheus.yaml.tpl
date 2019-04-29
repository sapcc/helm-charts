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

- job_name: 'prometheus-openstack-collector-regions-federation'
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
      regex: prometheus-collector-openstack.(.+).cloud.sap
      replacement: $1
    - action: replace
      target_label: cluster_type
      replacement: controlplane

  static_configs:
    - targets:
{{- range $region := .Values.regionList }}
      - "prometheus-collector-openstack.{{ $region }}.cloud.sap"
{{- end }}
