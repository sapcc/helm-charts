- job_name: 'jumpserver'
  params:
    job: [jumpserver]
  metrics_path: /metrics
  http_sd_configs:
    - url: {{ .Values.atlas_url }}
  relabel_configs:
    - source_labels: [job]
      regex: jumpserver
      action: keep
    - source_labels: [__address__]
      target_label: __address__
      regex:       '(.*)'
      replacement: $1:9100
  metric_relabel_configs:
    - regex: "role|server_id|state"
      action: labeldrop

{{- $values := .Values.windows_exporter -}}
{{- if $values.enabled }}
{{- $name := "win-exporter-ad" }}
- job_name: '{{ $name }}'
  scrape_interval: {{$values.scrapeInterval}}
  scrape_timeout: {{$values.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_production_url }}/virtual-machines/?custom_labels=job={{ $name }}&target=primary_ip&status=active&role=server&tenant=converged-cloud&platform=windows-server&tag=active-directory-domain-controller&region={{ .Values.global.region }}
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /metrics
  relabel_configs:
    - source_labels: [__address__]
      replacement: $1:{{$values.listen_port}}
      target_label: __address__
    - source_labels: [name]
      target_label: server_name
    - regex: 'name|state'
      action: labeldrop
  metric_relabel_configs:
    - source_labels: [__name__]
      regex: '^go_.+'
      action: drop
    - source_labels: ['__name__','exported_name']
      regex: 'windows_service_state;(.*)'
      replacement: '$1'
      target_label: 'service_name'
    - source_labels: ['__name__','exported_state']
      regex: 'windows_service_state;(.*)'
      replacement: '$1'
      target_label: 'service_state'

{{- $name := "win-exporter-wsus" }}
- job_name: '{{ $name }}'
  scrape_interval: {{$values.scrapeInterval}}
  scrape_timeout: {{$values.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_production_url }}/virtual-machines/?custom_labels=job={{ $name }}&target=primary_ip&status=active&q=wsus&role=server&tenant=converged-cloud&platform=windows-server&region={{ .Values.global.region }}
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /metrics
  relabel_configs:
    - source_labels: [__address__]
      replacement: $1:{{$values.listen_port}}
      target_label: __address__
    - source_labels: [name]
      target_label: server_name
    - regex: 'name|state'
      action: labeldrop
  metric_relabel_configs:
    - source_labels: [__name__]
      regex: '^go_.+'
      action: drop
    - source_labels: ['__name__','exported_name']
      regex: 'windows_service_state;(.*)'
      replacement: '$1'
      target_label: 'service_name'
    - source_labels: ['__name__','exported_state']
      regex: 'windows_service_state;(.*)'
      replacement: '$1'
      target_label: 'service_state'
{{- end }}

{{- $values := .Values.firmware_exporter -}}
{{- if $values.enabled }}
- job_name: 'firmware-exporter'
  params:
    job: [firmware-exporter]
  scrape_interval: {{$values.scrapeInterval}}
  scrape_timeout: {{$values.scrapeTimeout}}
  static_configs:
    - targets : ['firmware-exporter:9100']
  metrics_path: /
  relabel_configs:
    - source_labels: [job]
      regex: firmware-exporter
      action: keep
{{- end }}

{{ if .Values.ask1k_tests.enabled }}
- job_name: 'asr1k_tests'
  scrape_interval: 30s
  scrape_timeout: 25s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{__name__=~"(probe_.+_duration_seconds:avg|probe_success:avg)"}'
      - '{__name__=~".*probes_by_attributes"}'
      - '{__name__=~"tcpgoon_.*"}'
  static_configs:
    - targets:
      - 'prometheus.asr1k-tests.c.{{ .Values.global.region }}.cloud.sap:9090'
{{- if eq .Values.global.region "qa-de-1" }}
      - 'prometheus.asr1k-tests-monsoon.c.{{ .Values.global.region }}.cloud.sap:9090'
{{- end }}
{{ end }}

#exporter is leveraging service discovery but not part of infrastructure monitoring project itself.
{{- $values := .Values.ucs_exporter -}}
{{- if $values.enabled }}
- job_name: 'ucs'
  scrape_interval: {{$values.scrapeInterval}}
  scrape_timeout: {{$values.scrapeTimeout}}
  kubernetes_sd_configs:
  - role: service
    namespaces:
      names:
        - infra-monitoring
  metrics_path: /
  relabel_configs:
    - action: keep
      source_labels: [__meta_kubernetes_service_name]
      regex: ucs-exporter
{{- end }}
