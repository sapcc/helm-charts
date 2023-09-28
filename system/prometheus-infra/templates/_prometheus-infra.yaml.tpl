- job_name: 'prometheus-infra-snmp'
  scheme: https
  scrape_interval: {{ .Values.collector.scrapeInterval }}
  scrape_timeout: {{ .Values.collector.scrapeTimeout }}

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{job="snmp", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="snmp-apod", __name__!~"^(up|ALERTS.*|scrape.+)"}'

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: prometheus-infra-collector.(.+).cloud.sap
      replacement: $1

  metric_relabel_configs:
    - source_labels: [__name__, ifIndex, server_id]
      regex: '^snmp_[a-z0-9]*_if.+;(.+);(.+)'
      replacement: '$1@$2'
      target_label: uniqueident
      action: replace

  {{ if .Values.authentication.enabled }}
  tls_config:
    cert_file: /etc/prometheus/secrets/prometheus-infra-frontend-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/prometheus-infra-frontend-sso-cert/sso.key
  {{ end }}

  static_configs:
    - targets:
      - "prometheus-infra-collector.{{ .Values.global.region }}.cloud.sap"

- job_name: 'prometheus-infra-collector'
  scheme: https
  scrape_interval: {{ .Values.collector.scrapeInterval }}
  scrape_timeout: {{ .Values.collector.scrapeTimeout }}

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{app="thousandeyes-exporter", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{app="ping-exporter", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{app="vcsa-exporter", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="asw-eapi", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="bios/ironic", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="bios/cisco_cp", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="bios/vpod", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="ipmi/ironic", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="vmware-esxi", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="atlas", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="esxi-config", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="redfish/bb", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="redfish/bm", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="redfish/cp", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="ucs", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="ucs", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="netbox", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="firmware-exporter", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="win-exporter-ad", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{job="win-exporter-wsus", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{__name__=~"^global:cloudprober.+"}'
      - '{__name__=~"^elasticsearch_hermes_.+"}'
      - '{__name__=~"^probe_success",job=~"(infra|cc3test)-probe-.+"}'
      - '{__name__=~"^probe_success",job="docs-urls"}'
      - '{__name__=~"^probe_http_duration_seconds",job="docs-home-content"}'
      - '{__name__=~"^vcenter_.+",job!~"[a-z0-9-]*-vccustomervmmetrics$"}'
      - '{__name__=~"^network_apic_.+"}'
      - '{__name__=~"^ipmi_sensor_state$",type=~"Memory|Drive Slot|Processor|Power Supply|Critical Interrupt|Version Change|Event Logging Disabled|System Event"}'
      - '{__name__=~"^ipmi_memory_state$"}'
      - '{__name__=~"^ipmi_memory_errors$"}'
      - '{__name__=~"^ipmi_up"}'
      - '{job="logs-fluent-exporter", __name__!~"^(fluentd_input_status_num_records_total|fluentd_output_status_num_records_total)"}'
      - '{__name__=~"^bird_.+"}'
      - '{__name__=~"^pxcloudprober_.+"}'
      - '{__name__=~"^vasa_.+"}'
      - '{__name__=~"^ssh_.+"}'
      - '{__name__=~"^redfish_.+"}'
      - '{__name__=~"^nsxt_trim_exception"}'
      - '{__name__=~"^filebeat_.+"}'
      - '{__name__=~"^fluentbit.+"}'
      - '{__name__=~"^logstash_node_.+"}'
      - '{__name__=~"^prom_fluentd_.+"}'
      - '{__name__=~"^metis_.+"}'
      - '{__name__=~"^maria_backup.+"}'
      - '{__name__=~"^neutron_router:.+"}'

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: prometheus-infra-collector.(.+).cloud.sap
      replacement: $1

  metric_relabel_configs:
    - source_labels: [__name__, instance]
      regex: '^probe_success;(.+)'
      replacement: '$1'
      target_label: target
      action: replace
    - regex: "prometheus_replica|kubernetes_namespace|kubernetes_name|namespace|pod|pod_template_hash|instance"
      action: labeldrop

  {{ if .Values.authentication.enabled }}
  tls_config:
    cert_file: /etc/prometheus/secrets/prometheus-infra-frontend-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/prometheus-infra-frontend-sso-cert/sso.key
  {{ end }}

  static_configs:
    - targets:
      - "prometheus-infra-collector.{{ .Values.global.region }}.cloud.sap"