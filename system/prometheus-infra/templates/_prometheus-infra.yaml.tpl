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
      - '{app="cloudprober-exporter"}'
      - '{app="thousandeyes-exporter"}'
      - '{app="netapp-harvest"}'
      - '{app="netapp-api-exporter"}'
      - '{job="baremetal/arista"}'
      - '{job="bios/ironic"}'
      - '{job="ipmi/ironic"}'
      - '{job="snmp"}'
      - '{job=~"vcenter-exporter-.+"}'
      - '{job=~"blackbox/.+"}'

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: prometheus-infra-collector.(.+).cloud.sap
      replacement: $1
    - action: replace
      target_label: cluster_type
      replacement: controlplane
  metric_relabel_configs:
  - source_labels: [component, cluster]
    separator: ;
    regex: es-exporter-logs;(.+)
    target_label: elastic_cluster
    replacement: $1
    action: replace

  {{ if .Values.authentication.enabled }}
  tls_config:
    cert_file: /etc/prometheus/secrets/prometheus-infra-frontend-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/prometheus-infra-frontend-sso-cert/sso.key
  {{ end }}

  static_configs:
    - targets:
      - "prometheus-infra-collector.{{ .Values.global.region }}.cloud.sap"
