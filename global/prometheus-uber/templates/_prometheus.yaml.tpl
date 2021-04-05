- job_name: 'prometheus-global-federation'
  scheme: https
  scrape_interval: 30s
  scrape_timeout: 25s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{__name__=~"^ALERTS$"}'
      - '{__name__=~"^prometheus_build_info$"}'

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: prometheus-kubernetes.(.+).cloud.sap
      replacement: $1

    - action: replace
      target_label: cluster_type
      replacement: controlplane

  metric_relabel_configs:
    - action: replace
      source_labels: [__name__]
      target_label: __name__
      regex: global:(.+)
      replacement: $1

  {{ if .Values.authentication.enabled }}
  tls_config:
    cert_file: /etc/prometheus/secrets/prometheus-uber-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/prometheus-uber-sso-cert/sso.key
  {{ end }}

  static_configs:
    - targets:
        - prometheus-kubernetes.global.cloud.sap
        - prometheus-kubernikus.global.cloud.sap
        - prometheus-openstack.global.cloud.sap
        - prometheus-infra.global.cloud.sap
