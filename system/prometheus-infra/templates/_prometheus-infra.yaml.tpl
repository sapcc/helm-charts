- job_name: 'prometheus-infra-collector'
  scheme: https
  scrape_interval: {{ .Values.collector.scrapeInterval }}
  scrape_timeout: {{ .Values.collector.scrapeTimeout }}

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{app="cloudprober-exporter"}'
      - '{app="thousandeyes-exporter"}'
      - '{app="netapp-harvest"}'
      - '{app="netapp-api-exporter"}'
      - '{app=~"^netapp-capacity-exporter.*"}'
      - '{app=~"^netapp-perf-exporter.*"}'
      - '{app="ping-exporter"}'
      - '{job="vcenter"}'
      - '{job="asw-eapi"}'
      - '{job="bios/ironic"}'
      - '{job="bios/cisco_vpod"}'
      - '{job="ipmi/ironic"}'
      - '{job="vmware-esxi"}'
      - '{job="snmp"}'
      - '{job="infra-monitoring-atlas-sd"}'
      - '{__name__=~"^vcenter_.+"}'
      - '{__name__=~"^network_apic_.+"}'
      - '{__name__=~"^ipmi_sensor_state$",type=~"Memory|Drive Slot|Processor|Power Supply|Critical Interrupt|Version Change|Event Logging Disabled|System Event"}'
      - '{__name__=~"^ipmi_memory_errors$"}'
      - '{__name__=~"^ipmi_up"}'
      - '{__name__=~"^bird_.+"}'
      - '{__name__=~"^up"}'

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
    - regex: "prometheus_replica|kubernetes_namespace|kubernetes_name|namespace|pod|pod_template_hash|instance"
      action: labeldrop
    - source_labels: [__name__, prometheus]
      regex: '^up;(.+)'
      replacement: '$1'
      target_label: prometheus_source
      action: replace
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
