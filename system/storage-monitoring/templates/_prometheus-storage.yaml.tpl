{{- if .Values.netapp_cap_exporter.enabled }}
{{- range $name, $app := .Values.netapp_cap_exporter.apps }}
- job_name: '{{ $app.fullname }}'
  scrape_interval: {{ required ".Values.netapp_cap_exporter.apps[].scrapeInterval" $app.scrapeInterval }}
  scrape_timeout: {{ required ".Values.netapp_cap_exporter.apps[].scrapeTimeout" $app.scrapeTimeout }}
  static_configs:
    - targets:
      - '{{ $app.fullname }}:9108'
  metrics_path: /metrics
  relabel_configs:
    - source_labels: [job]
      regex: {{ $app.fullname }}
      action: keep
    - source_labels: [job]
      target_label: app
      replacement: ${1}
      action: replace
{{- end }}
{{- end }}

# exception for castellum to shift load from thanos-metal-query
- job_name: 'prometheus-openstack-federation'
  scrape_interval: 1m
  scrape_timeout: 55s
  static_configs:
    - targets: ['prometheus-openstack.prometheus-openstack:9090']
  metrics_path: '/federate'
  params:
    'match[]':
      - '{__name__="manila_share_exclusion_reasons_for_castellum"}'
  metric_relabel_configs:
    - regex: "cluster|cluster_type|prometheus|prometheus_replica|region"
      action: labeldrop
