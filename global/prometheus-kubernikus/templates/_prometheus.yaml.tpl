- job_name: 'prometheus-kubernikus-regions-federation'
  scheme: https
  scrape_interval: 30s
  scrape_timeout: 25s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{__name__=~"^ALERTS$"}'
      - '{__name__=~"^kubernikus_kluster_status_phase"}'
      - '{__name__=~"^kubernikus_kluster_info"}'
      - '{__name__=~"^kubernikus_servicing_nodes.+"}'
      - '{__name__=~"up"}'

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: prometheus.kubernikus.(.+).cloud.sap
      replacement: $1
    - action: replace
      target_label: cluster_type
      replacement: kubernikus-controlplane

  metric_relabel_configs:
    - action: replace
      source_labels: [__name__]
      target_label: __name__
      regex: global:(.+)
      replacement: $1

  {{ if .Values.authentication.enabled }}
  tls_config:
    cert_file: /etc/prometheus/secrets/prometheus-kubernikus-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/prometheus-kubernikus-sso-cert/sso.key
  {{ end }}

  static_configs:
    - targets:
{{- range $region := .Values.regionList }}
      - "prometheus.kubernikus.{{ $region }}.cloud.sap"
{{- end }}
