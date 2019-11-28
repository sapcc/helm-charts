- job_name: 'prometheus-regions-federation'
  scheme: https
  scrape_interval: 30s
  scrape_timeout: 25s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{__name__=~"^ALERTS$"}'
      - '{__name__=~"^global:.+"}'
      - '{__name__=~"up"}'
      - '{__name__=~"prometheus_build_info}'
      - '{__name__=~"blackbox_regression_status_gauge"}'
      - '{__name__=~"^openstack_ironic_nodes_.+"}'
      - '{__name__=~"^openstack_ironic_leftover_ports$"}'      
      - '{__name__=~"^limes_domain_quota$", resource=~"instances_z.*"}'
      - '{__name__=~"^limes_project_.+$", resource=~"instances_z.*"}'
      - '{__name__=~"^nsxv3_cluster_(management|control)_status$"}'
      - '{__name__=~"^elektra_open_inquiry_metrics$"}'
      - '{__name__=~"^blackbox_integrity_status_gauge", check=~"esxi_hs-.+"}'

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: prometheus-openstack.(.+).cloud.sap
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
    cert_file: /etc/prometheus/secrets/prometheus-openstack-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/prometheus-openstack-sso-cert/sso.key
  {{ end }}

  static_configs:
    - targets:
{{- range $region := .Values.regionList }}
      - "prometheus-openstack.{{ $region }}.cloud.sap"
{{- end }}
