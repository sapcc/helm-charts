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
