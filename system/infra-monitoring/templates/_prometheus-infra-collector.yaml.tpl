# Scrape config for pods
#
# The relabeling allows the actual pod scrape endpoint to be configured via the
# following annotations:
#
# * `prometheus.io/scrape`: Only scrape pods that have a value of `true`
# * `prometheus.io/path`: If the metrics path is not `/metrics` override this.
# * `prometheus.io/port`: Scrape the pod on the indicated port instead of the default of `9102`.
- job_name: 'pods'
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - action: keep
    source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
    regex: true
  - action: keep
    source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_targets]
    regex: .*infra-collector.*
  - action: keep
    source_labels: [__meta_kubernetes_pod_container_port_number, __meta_kubernetes_pod_container_port_name, __meta_kubernetes_pod_annotation_prometheus_io_port]
    regex: (9102;.*;.*)|(.*;metrics;.*)|(.*;.*;\d+)
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
    target_label: __metrics_path__
    regex: (.+)
  - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
    target_label: __address__
    regex: ([^:]+)(?::\d+)?;(\d+)
    replacement: ${1}:${2}
  - action: labelmap
    regex: __meta_kubernetes_pod_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_pod_name]
    target_label: kubernetes_pod_name
  metric_relabel_configs:
    - regex: "instance|kubernetes_namespace|kubernetes_pod_name|kubernetes_name|pod_template_hash|exported_instance"
      action: labeldrop
    - source_labels: [__name__, target]
      regex: '^ping_.+;www-(\w*)-(\w*-\w*-\w*).+'
      replacement: '$1'
      target_label: probed_to_type
    - source_labels: [__name__, target]
      regex: '^ping_.+;([a-zA-Z]*)(\d)\.cc\.(.+)\.cloud\.sap'
      replacement: '$1'
      target_label: probed_to_type
    - source_labels: [__name__, target]
      regex: '^ping_.+;cloudprober-.+'
      replacement: 'pod'
      target_label: probed_to_type
    - source_labels: [__name__, target]
      regex: '^ping_.+;www-(\w*)-(\w*-\w*-\w*).+'
      replacement: '$2'
      target_label: probed_to
    - source_labels: [__name__, target]
      regex: '^ping_.+;([a-zA-Z]*)0\.cc\.(.+)\.cloud\.sap'
      replacement: ${2}a
      target_label: probed_to
    - source_labels: [__name__, target]
      regex: '^ping_.+;([a-zA-Z]*)1\.cc\.(.+)\.cloud\.sap'
      replacement: ${2}b
      target_label: probed_to
    - source_labels: [__name__, target]
      regex: '^ping_.+;cloudprober-(\w*-\w*-\w*).+'
      replacement: '$1'
      target_label: probed_to
    - source_labels: [__name__, probe]
      regex: '^cloudprober_.+;(ping|http)-([a-zA-Z]*)-(.+)'
      replacement: '$2'
      target_label: probed_to_type
    - source_labels: [__name__, probe]
      regex: '^cloudprober_.+;(ping|http)-([a-zA-Z]*)-(.+)'
      replacement: '$3'
      target_label: probed_to
    - source_labels: [__name__]
      regex: '^cloudprober_.+'
      replacement: 'region'
      target_label: interconnect_type
    - source_labels: [__name__, probe]
      regex: '^cloudprober_.+;(ping|http)-[a-zA-Z]*-{{ .Values.global.region }}.+'
      replacement: 'dc'
      target_label: interconnect_type
    - source_labels: [__name__]
      regex: '^ping_.+'
      replacement: 'region'
      target_label: interconnect_type
    - source_labels: [__name__, target]
      regex: '^ping_.+;([a-zA-Z]*)\d\.cc\.{{ .Values.global.region }}\.cloud\.sap'
      replacement: 'dc'
      target_label: interconnect_type
    - source_labels: [__name__, app]
      regex: '^bird_.+;{{ .Values.global.region }}-pxrs-([0-9])-s([0-9])-([0-9])'
      replacement: '$1'
      target_label: pxdomain
    - source_labels: [__name__, app]
      regex: '^bird_.+;{{ .Values.global.region }}-pxrs-([0-9])-s([0-9])-([0-9])'
      replacement: '$2'
      target_label: pxservice
    - source_labels: [__name__, app]
      regex: '^bird_.+;{{ .Values.global.region }}-pxrs-([0-9])-s([0-9])-([0-9])'
      replacement: '$3'
      target_label: pxinstance
    - source_labels: [__name__, proto, import_filter]
      regex: '^bird_.+;BGP;.+_IMPORT_(\w*)_(\w*_\w*)$'
      replacement: '$1'
      target_label: peer_type
    - source_labels: [__name__, proto, import_filter]
      regex: '^bird_.+;BGP;.+_IMPORT_(\w*)_(\w*_\w*)$'
      replacement: '$2'
      target_label: peer_id

# Scrape config for pods with an additional port for metrics via `prometheus.io/port_1` annotation.
#
# * `prometheus.io/scrape`: Only scrape pods that have a value of `true`
# * `prometheus.io/path`: If the metrics path is not `/metrics` override this.
# * `prometheus.io/port_1`: Scrape the pod on the indicated port instead of the default of `9102`.
- job_name: 'pods_metric_port_1'
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - action: keep
    source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
    regex: true
  - action: keep
    source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_targets]
    regex: .*infra-collector.*
  - action: keep
    source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port_1]
    regex: \d+
  - action: keep
    source_labels: [__meta_kubernetes_pod_container_port_number, __meta_kubernetes_pod_container_port_name, __meta_kubernetes_pod_annotation_prometheus_io_port_1]
    regex: (9102;.*;.*)|(.*;metrics;.*)|(.*;.*;\d+)
  - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
    target_label: __metrics_path__
    regex: (.+)
  - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port_1]
    target_label: __address__
    regex: ([^:]+)(?::\d+)?;(\d+)
    replacement: ${1}:${2}
  - action: labelmap
    regex: __meta_kubernetes_pod_label_(.+)
  - source_labels: [__meta_kubernetes_namespace]
    target_label: kubernetes_namespace
  - source_labels: [__meta_kubernetes_pod_name]
    target_label: kubernetes_pod_name
  metric_relabel_configs:
    - regex: "instance|job|kubernetes_namespace|kubernetes_pod_name|kubernetes_name|pod_template_hash|exported_instance|exported_job|type|name|component|system"
      action: labeldrop
    - source_labels: [__name__, target]
      regex: 'ping_.+;www-(\w*)-(\w*-\w*-\w*).+'
      replacement: '$2'
      target_label: probed_to
    - source_labels: [__name__, target]
      regex: 'ping_.+;www-(\w*)-(\w*-\w*-\w*).+'
      replacement: '$1'
      target_label: probed_to_type

{{- $values := .Values.arista_exporter -}}
{{- if $values.enabled }}
- job_name: 'arista'
  scrape_interval: {{$values.scrapeInterval}}
  scrape_timeout: {{$values.scrapeTimeout}}
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/atlas-sd/netbox.json
  metrics_path: /arista
  relabel_configs:
    - source_labels: [job]
      regex: asw-eapi
      action: keep
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: arista-exporter:9200
{{- end }}

{{- $values := .Values.snmp_exporter -}}
{{- if $values.enabled }}
- job_name: 'snmp'
  scrape_interval: {{$values.scrapeInterval}}
  scrape_timeout: {{$values.scrapeTimeout}}
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/atlas-sd/netbox.json
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [job]
      regex: snmp
      action: keep
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{$values.listen_port}}
    - source_labels: [module]
      target_label: __param_module
  metric_relabel_configs:
    - source_labels: [server_name]
      target_label:  devicename
    - source_labels: [devicename]
      regex: '(\w*-\w*-\w*)-(\S*)'
      replacement: '$1'
      target_label: availability_zone
    - source_labels: [devicename]
      regex: '(\w*-\w*-\w*)-(\S*)'
      replacement: '$2'
      target_label: device
    - source_labels: [__name__, snmp_n3k_sysDescr]
      regex: 'snmp_n3k_sysDescr;(?s)(.*)(Version )([0-9().a-zIU]*)(,.*)'
      replacement: '$3'
      target_label: image_version
    - source_labels: [__name__, snmp_pxdlrouternxos_ciscoImageString]
      regex: 'snmp_pxdlrouternxos_ciscoImageString;(.*)(\$)(.*)(\$)'
      replacement: '$3'
      target_label: image_version
    - source_labels: [__name__, snmp_n9kpx_ciscoImageString]
      regex: 'snmp_n9kpx_ciscoImageString;(.*)(\$)(.*)(\$)'
      replacement: '$3'
      target_label: image_version
    - source_labels: [__name__, snmp_ipn_sysDescr]
      regex: 'snmp_ipn_sysDescr;(?s)(.*)(Version )([0-9().a-zIU]*)(,.*)'
      replacement: '$3'
      target_label: image_version
    - source_labels: [__name__, snmp_arista_entPhysicalSoftwareRev]
      regex: 'snmp_arista_entPhysicalSoftwareRev;(.*)'
      replacement: '$1'
      target_label: image_version
    - source_labels: [__name__, snmp_asa_sysDescr]
      regex: 'snmp_asa_sysDescr;([a-zA-Z ]*)([0-9().]*)'
      replacement: '$2'
      target_label: image_version
    - source_labels: [__name__, device]
      regex: 'snmp_asa_sysDescr;(ASA0102-CC-CORP|AsSA0102-CC-DMZ|ASA0102-CC-HEC|ASA0102-CC-INTERNET|ASA0102-CC-SAAS|ASA0102a-CC-HEC|ASA0102a-CC-DMZ|ASA0102a-CC-CORP|ASA0102a-CC-INTERNET|ASA0102a-CC-SAAS)'
      action: drop
    - source_labels: [__name__, ifDescr]
      regex: 'snmp_acileaf_if.+;(Tunnel)[0-9]*'
      action: drop
    - source_labels: [__name__, snmp_acileaf_sysDescr]
      regex: 'snmp_acileaf_sysDescr;(?s)(.*)(Version )([0-9().a-z]*)(,.*)'
      replacement: '$3'
      target_label: image_version
    - source_labels: [__name__, snmp_acispine_sysDescr]
      regex: 'snmp_acispine_sysDescr;(?s)(.*)(Version )([0-9().a-z]*)(,.*)'
      replacement: '$3_$4'
      target_label: image_version
    - source_labels: [__name__, snmp_asr_sysDescr]
      regex: 'snmp_asr_sysDescr;(?s)(.*)(Version )([0-9().a-zIU:]*)([0-9A-Z_]*)(.*)'
      replacement: ${1}${2}
      target_label: image_version
    - source_labels: [__name__, snmp_asr03_sysDescr]
      regex: 'snmp_asr03_sysDescr;(?s)(.*)(Version )([0-9().a-z]*)(,.*)'
      replacement: '$3'
      target_label: image_version
    - source_labels: [__name__, snmp_asr04_sysDescr]
      regex: 'snmp_asr04_sysDescr;(?s)(.*)(Version )([0-9().a-z]*)(,.*)'
      replacement: '$3'
      target_label: image_version
    - source_labels: [__name__, snmp_f5_sysProductVersion]
      regex: 'snmp_f5_sysProductVersion;(.*)'
      replacement: '$1'
      target_label: image_version
    - source_labels: [__name__, snmp_acistretch_sysDescr]
      regex: "snmp_acistretch_sysDescr;(?s)(.*)Version ([0-9.]*)(.*)"
      replacement: '$2'
      target_label: image_version
    - source_labels: [__name__, snmp_n7k_sysDescr]
      regex: 'snmp_n7k_sysDescr;(?s)(.*)(Version )([0-9().a-z]*)(,.*)'
      replacement: '$3'
      target_label: image_version
# hack to mitigate some false-positive snmp_asr_ alerts due to netbox naming pattern devicename="LA-BR-1-ASR11a"
    - source_labels: [__name__, devicename]
      regex: 'snmp_asr_RedundancyGroup;(\w*-\w*-\w*)-(\S*).$'
      replacement: '$2'
      target_label: device
{{- end }}

{{- $values := .Values.bios_exporter -}}
{{- if $values.enabled }}
- job_name: 'bios/ironic'
  params:
    job: [bios/ironic]
  scrape_interval: {{$values.ironic_scrapeInterval}}
  scrape_timeout: {{$values.ironic_scrapeTimeout}}
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/atlas-sd/ironic.json
  metrics_path: /
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: bios-exporter:{{$values.listen_port}}
    - source_labels: [manufacturer]
      target_label:  __param_manufacturer
    - source_labels: [model]
      target_label:  __param_model
- job_name: 'bios/vpod'
  params:
    job: [bios/vpod]
  scrape_interval: {{$values.vpod_scrapeInterval}}
  scrape_timeout: {{$values.vpod_scrapeTimeout}}
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/atlas-sd/netbox.json
  metrics_path: /
  relabel_configs:
    - source_labels: [job]
      regex: bios/vpod
      action: keep
    - source_labels: [server_name]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: bios-exporter:{{$values.listen_port}}
    - source_labels: [manufacturer]
      target_label:  __param_manufacturer
    - source_labels: [model]
      target_label:  __param_model
    - source_labels: [job]
      target_label: __param_job
- job_name: 'bios/cisco_cp'
  params:
    job: [bios/cisco_cp]
  scrape_interval: {{$values.cisco_cp_scrapeInterval}}
  scrape_timeout: {{$values.cisco_cp_scrapeTimeout}}
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/atlas-sd/netbox.json
  metrics_path: /
  relabel_configs:
    - source_labels: [job]
      regex: bios/cisco_cp
      action: keep
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: bios-exporter:{{$values.listen_port}}
    - source_labels: [manufacturer]
      target_label:  __param_manufacturer
    - source_labels: [model]
      target_label:  __param_model
    - source_labels: [server_name]
      target_label: __param_name
    - source_labels: [job]
      target_label: __param_job
{{- end }}

{{- $values := .Values.ipmi_exporter -}}
{{- if $values.enabled }}
- job_name: 'ipmi/ironic'
  params:
    job: [baremetal/ironic]
  scrape_interval: {{$values.ironic_scrapeInterval}}
  scrape_timeout: {{$values.ironic_scrapeTimeout}}
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/atlas-sd/ironic.json
  metrics_path: /ipmi
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: ipmi-exporter:{{$values.listen_port}}

- job_name: 'cp/netbox'
  params:
    job: [cp/netbox]
  scrape_interval: {{$values.cp_scrapeInterval}}
  scrape_timeout: {{$values.cp_scrapeTimeout}}
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/atlas-sd/netbox.json
  metrics_path: /ipmi
  relabel_configs:
    - source_labels: [job]
      regex: cp/netbox
      action: keep
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: ipmi-exporter:{{$values.listen_port}}
    - source_labels: [__meta_serial]
      target_label: server_serial

- job_name: 'ipmi/esxi'
  params:
    job: [esxi]
  scrape_interval: {{$values.esxi_scrapeInterval}}
  scrape_timeout: {{$values.esxi_scrapeTimeout}}
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/atlas-sd/netbox.json
  metrics_path: /ipmi
  relabel_configs:
    - source_labels: [job]
      regex: vmware-esxi
      action: keep
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: ipmi-exporter:{{$values.listen_port}}
{{- end }}

{{- $values := .Values.redfish_exporter -}}
{{- if $values.enabled }}
- job_name: 'redfish/bm'
  params:
    job: [redfish/bm]
  scrape_interval: {{$values.bm_scrapeInterval}}
  scrape_timeout: {{$values.bm_scrapeTimeout}}
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/atlas-sd/netbox.json
  metrics_path: /redfish
  relabel_configs:
    - source_labels: [job]
      regex: redfish/bm
      action: keep
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: redfish-exporter:{{$values.listen_port}}

- job_name: 'redfish/cp'
  params:
    job: [redfish/cp]
  scrape_interval: {{$values.cp_scrapeInterval}}
  scrape_timeout: {{$values.cp_scrapeTimeout}}
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/atlas-sd/netbox.json
  metrics_path: /redfish
  relabel_configs:
    - source_labels: [job]
      regex: redfish/cp
      action: keep
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: redfish-exporter:{{$values.listen_port}}
    - source_labels: [__meta_serial]
      target_label: server_serial

- job_name: 'redfish/bb'
  params:
    job: [redfish/bb]
  scrape_interval: {{$values.bb_scrapeInterval}}
  scrape_timeout: {{$values.bb_scrapeTimeout}}
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/atlas-sd/netbox.json
  metrics_path: /redfish
  relabel_configs:
    - source_labels: [job]
      regex: redfish/bb
      action: keep
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: redfish-exporter:{{$values.listen_port}}
{{- end }}

{{- $values := .Values.vasa_exporter -}}
{{- if $values.enabled }}
- job_name: 'vasa'
  scrape_interval: {{$values.scrapeInterval}}
  scrape_timeout: {{$values.scrapeTimeout}}
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/atlas-sd/netbox.json
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

{{- if .Values.alertmanager_exporter.enabled }}
- job_name: 'prometheus/alertmanager'
  scrape_interval: {{ .Values.alertmanager_exporter.scrapeInterval }}
  scrape_timeout: {{ .Values.alertmanager_exporter.scrapeTimeout }}
  static_configs:
    - targets:
      {{- range $.Values.alertmanager_exporter.targets }}
      - {{ . }}
      {{- end }}
  scheme: https
{{- end }}

#exporter is leveraging service discovery but not part of infrastructure monitoring project itself.
{{- $values := .Values.vrops_exporter -}}
{{- if $values.enabled }}
- job_name: 'vrops'
  scrape_interval: {{$values.scrapeInterval}}
  scrape_timeout: {{$values.scrapeTimeout}}
  static_configs:
    - targets: ['vrops-exporter:9160']
  metrics_path: /
  relabel_configs:
    - source_labels: [job]
      regex: vrops
      action: keep
{{- end }}

#exporter is leveraging service discovery but not part of infrastructure monitoring project itself.
{{- $values := .Values.esxi_exporter -}}
{{- if $values.enabled }}
- job_name: 'esxi-config'
  scrape_interval: {{$values.scrapeInterval}}
  scrape_timeout: {{$values.scrapeTimeout}}
  file_sd_configs:
      - files :
        - /etc/prometheus/configmaps/atlas-sd/netbox.json
  metrics_path: /
  relabel_configs:
    - source_labels: [job]
      regex: vcenter
      action: keep
    - source_labels: [server_name]
      target_label: __param_target
    - target_label: __address__
      replacement: esxi-exporter:9203
{{- end }}
- job_name: 'bm-cablecheck-exporter'
  params:
    job: [bm-cablecheck-exporter]
  scrape_interval: {{$values.bm-cablecheck_scrapeInterval}}
  scrape_timeout: {{$values.bm-cablecheck_scrapeTimeout}}
  static_configs:
      - targets :
        - cablecheck-exporter:9100
