- job_name: 'prometheus-infra-collection'
  scheme: https
  scrape_interval: 30s
  scrape_timeout: 25s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{__name__=~"^ALERTS"}'
      - '{__name__=~"up"}'
      - '{__name__=~"^success"}'
      - '{__name__=~"^latency"}'

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: prometheus-infra-collector.(.+).cloud.sap
      replacement: $1
    - action: replace
      target_label: cluster_type
      replacement: controlplane

  {{ if .Values.authentication.enabled }}
  tls_config:
    cert_file: /etc/prometheus/secrets/prometheus-infra-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/prometheus-infra-sso-cert/sso.key
  {{ end }}

  static_configs:
    - targets:
      - "prometheus-infra-collector.{{ .Values.global.region }}.cloud.sap"