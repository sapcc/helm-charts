- job_name: 'prometheus-regions-federation'
  scheme: https
  scrape_interval: 30s
  scrape_timeout: 25s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{__name__=~"^global:.+"}'
      - '{__name__=~"prometheus_build_info"}'
      - '{__name__=~"blackbox_regression_status_gauge"}'
      - '{__name__=~"^openstack_ironic_nodes_.+"}'
      - '{__name__=~"^openstack_ironic_leftover_ports$"}'
      - '{__name__=~"^limes_domain_quota$", resource=~"instances_.*"}'
      - '{__name__=~"^limes_project_.+$", resource=~"instances_.*"}'
      - '{__name__=~"^nsxv3_cluster_(management|control)_status$"}'
      - '{__name__=~"^nsxv3_management_node_version$"}'
      - '{__name__=~"^nsxv3_scheduler.*$"}'
      - '{__name__=~"^elektra_open_inquiry_metrics$"}'
      - '{__name__=~"^blackbox_integrity_status_gauge", check=~"esxi_hs-.+"}'
      - '{__name__=~"^octavia_as3_version_info$"}'
      - '{__name__=~"^cinder_.+"}'
      - '{__name__=~"^nginx_ingress_controller_requests", ingress=~".+-api$"}'
      - '{__name__=~"^nginx_ingress_controller_requests", ingress=~"keystone"}'
      - '{__name__=~"^nginx_ingress_controller_requests", ingress=~"neutron-server"}'
      - '{__name__=~"^nginx_ingress_controller_requests", ingress=~"elektra"}'
      - '{__name__=~"^pg_database_size_bytes$", namespace=~"(arc|lyra|elektra)"}'
      - '{__name__=~"^es_cluster_.+"}'
      - '{__name__=~"^es_fs_.+"}'
      - '{__name__=~"^es_indices_store_size_bytes"}'
      - '{__name__=~"^es_indices_doc_number"}'

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
