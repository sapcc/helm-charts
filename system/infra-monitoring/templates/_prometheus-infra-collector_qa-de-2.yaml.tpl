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

{{- $values := .Values.vasa_exporter -}}
{{- if $values.enabled }}
- job_name: 'vasa'
  scrape_interval: {{$values.scrapeInterval}}
  scrape_timeout: {{$values.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.atlas_url }}
  metrics_path: /
  relabel_configs:
    - source_labels: [job]
      regex: vcenter
      action: keep
    - source_labels: [server_name]
      target_label: __param_target
    - target_label: __address__
      replacement: vasa-exporter:{{$values.listen_port}}
{{- end }}

{{- if .Values.netbox_exporter.enabled }}
- job_name: 'netbox'
  scrape_interval: {{ .Values.netbox_exporter.scrapeInterval }}
  scrape_timeout: {{ .Values.netbox_exporter.scrapeTimeout }}
  static_configs:
    - targets:
      {{- range $.Values.netbox_exporter.targets }}
      - {{ . }}
      {{- end }}
  scheme: https
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

{{- if .Values.netapp_cap_exporter.enabled}}
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

{{ $root := . }}
{{- range $target := .Values.global.targets }}
- job_name: {{ include "prometheusVMware.fullName" (list $target $root) }}
  scheme: http
  scrape_interval: {{ $root.Values.prometheus_vmware.scrapeInterval }}
  scrape_timeout: {{ $root.Values.prometheus_vmware.scrapeTimeout }}
  # use the alertmanger cert, as it is the shared Prometheus cert
  tls_config:
    cert_file: /etc/prometheus/secrets/prometheus-infra-collector-alertmanager-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/prometheus-infra-collector-alertmanager-sso-cert/sso.key
  static_configs:
    - targets:
        - '{{ include "prometheusVMware.fullName" (list $target $root) }}-internal.{{ $root.Values.global.region }}.cloud.sap'
  honor_labels: true
  metrics_path: '/federate'
  params:
    'match[]':
      - '{__name__=~"vrops_hostsystem_runtime_maintenancestate"}'
{{- end }}
