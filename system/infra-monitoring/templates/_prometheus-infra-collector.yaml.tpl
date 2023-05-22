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

{{- $values := .Values.arista_exporter -}}
{{- if $values.enabled }}
- job_name: 'arista'
  scrape_interval: {{$values.scrapeInterval}}
  scrape_timeout: {{$values.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.atlas_url }}
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

- job_name: 'snmp'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.atlas_url }}
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
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
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
    - source_labels: [__name__, snmp_aristaevpn_sysDescr]
      regex: 'snmp_aristaevpn_sysDescr;(?s)(.*)(version )([0-9.a-zA-Z]*)(.*)'
      replacement: '$3'
      target_label: image_version
    - source_labels: [__name__, snmp_coreasr9k_sysDescr]
      regex: 'snmp_coreasr9k_sysDescr;(?s)(.*)(Version )([0-9.]*)(.*)'
      replacement: '$3'
      target_label: image_version
    - source_labels: [__name__, snmp_pxgeneric_sysDescr]
      regex: 'snmp_pxgeneric_sysDescr;(.*)(, Version )([0-9().a-zIU]*)((?s).*)'
      replacement: '$3'
      target_label: image_version
    - source_labels: [__name__, snmp_n9kpx_ciscoImageString]
      regex: 'snmp_n9kpx_ciscoImageString;(.*)(\$)(.*)(\$)'
      replacement: '$3'
      target_label: image_version
    - source_labels: [__name__,inetCidrRouteProto]
      regex: 'snmp_n9kpx_inetCidrRouteProto;(bbnSpfIgp|ttdp|rpl|rip|other|netmgmt|isIs|idpr|icmp|hello|ggp|esIs|egp|dvmrp|dhcp|ciscoIgrp|ciscoEigrp|bgp)'
      action: drop
    - source_labels: [__name__,inetCidrRouteStatus]
      regex: 'snmp_n9kpx_inetCidrRouteStatus;(createAndGo|createAndWait|destroy|notInService|notReady)'
      action: drop
    - source_labels: [__name__, snmp_ipn_sysDescr]
      regex: 'snmp_ipn_sysDescr;(?s)(.*)(Version )([0-9().a-zIU]*)(,.*)'
      replacement: '$3'
      target_label: image_version
    - source_labels: [__name__, snmp_arista_entPhysicalSoftwareRev]
      regex: 'snmp_arista_entPhysicalSoftwareRev;(.*)'
      replacement: '$1'
      target_label: image_version
    - source_labels: [__name__, etherStatsIndex]
      regex: 'snmp_arista_etherStatsCRCAlignErrors;(1\.3\.6\.1\.2\.1\.2\.2\.1\.1\.)([0-9]*)'
      replacement: '$2'
      target_label: ifIndex
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
      replacement: '$3'
      target_label: image_version
    - source_labels: [__name__, snmp_asr_sysDescr]
      regex: 'snmp_asr_sysDescr;(?s)(.*)(Version )([0-9().a-zIU:]*)(, )?(CUST-SPECIAL:)?([A-Z0-9_]*)?(.*)'
      replacement: ${3}${6}
      target_label: image_version
    - source_labels: [__name__, snmp_asr03_sysDescr]
      regex: 'snmp_asr03_sysDescr;(?s)(.*)(Version )([0-9().a-z]*)(,.*)'
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
    - source_labels: [__name__, cucsEtherErrStatsDn]
      regex: 'snmp_ucs_cucsEtherErrStats.+;.+(lan).+'
      action: drop
    - source_labels: [__name__, cucsFcErrStatsDn]
      regex: 'snmp_ucs_cucsFcErrStats.+;.+(port)-([3-9]|\d{2}).+'
      action: drop
    - source_labels: [__name__, ifAlias]
      regex: '^snmp_asr_.+;([a-z:]+);(project|)*:?([a-z0-9)]*);?router:([a-z0-9-]*);network:([a-z0-9-]*);subnet:([a-z0-9-]*)'
      replacement: '$3'
      target_label: project_id
    - source_labels: [__name__, ifAlias]
      regex: '^snmp_asr_.+;([a-z:]+);(project|)*:?([a-z0-9)]*);?router:([a-z0-9-]*);network:([a-z0-9-]*);subnet:([a-z0-9-]*)'
      replacement: '$4'
      target_label: router_id
    - source_labels: [__name__, ifAlias]
      regex: '^snmp_asr_.+;([a-z:]+);(project|)*:?([a-z0-9)]*);?router:([a-z0-9-]*);network:([a-z0-9-]*);subnet:([a-z0-9-]*)'
      replacement: '$5'
      target_label: network_id
    - source_labels: [__name__, ifAlias]
      regex: '^snmp_asr_.+;([a-z:]+);(project|)*:?([a-z0-9)]*);?router:([a-z0-9-]*);network:([a-z0-9-]*);subnet:([a-z0-9-]*)'
      replacement: '$6'
      target_label: subnet_id
    - source_labels: [__name__, device]
      regex: '^snmp_asr_[A-za-z0-9]+;((rt|asr)[0-9]+)[a|b]$'
      replacement: '$1'
      target_label: asr_pair
      action: replace

{{- $values := .Values.ipmi_exporter -}}
{{- if $values.enabled }}
- job_name: 'ipmi/ironic'
  params:
    job: [baremetal/ironic]
  scrape_interval: {{$values.ironic_scrapeInterval}}
  scrape_timeout: {{$values.ironic_scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.atlas_ironic_url }}
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
  http_sd_configs:
    - url: {{ .Values.atlas_url }}
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
  http_sd_configs:
    - url: {{ .Values.atlas_url }}
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
  scrape_interval: {{$values.redfish_scrapeInterval}}
  scrape_timeout: {{$values.redfish_scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.atlas_url }}
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
      replacement: redfish-exporter:9220

- job_name: 'redfish/cp'
  params:
    job: [redfish/cp]
  scrape_interval: {{$values.redfish_scrapeInterval}}
  scrape_timeout: {{$values.redfish_scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.atlas_url }}
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
      replacement: redfish-exporter:9220
    - source_labels: [__meta_serial]
      target_label: server_serial

- job_name: 'redfish/bb'
  params:
    job: [redfish/bb]
  scrape_interval: {{$values.redfish_scrapeInterval}}
  scrape_timeout: {{$values.redfish_scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.atlas_url }}
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
      replacement: redfish-exporter:9220
{{- end }}

{{- $values := .Values.windows_exporter -}}
{{- if $values.enabled }}
- job_name: 'win-exporter-ad'
  scrape_interval: {{$values.scrapeInterval}}
  scrape_timeout: {{$values.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.atlas_url }}
  metrics_path: /metrics
  relabel_configs:
    - source_labels: [job]
      regex: win-exporter-ad
      action: keep
    - source_labels: [__address__]
      replacement: $1:{{$values.listen_port}}
      target_label: __address__
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

- job_name: 'win-exporter-wsus'
  scrape_interval: {{$values.scrapeInterval}}
  scrape_timeout: {{$values.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.atlas_url }}
  metrics_path: /metrics
  relabel_configs:
    - source_labels: [job]
      regex: win-exporter-wsus
      action: keep
    - source_labels: [__address__]
      replacement: $1:{{$values.listen_port}}
      target_label: __address__
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

{{ if .Values.network_generic_ssh_exporter.enabled }}
- job_name: 'network/ssh'
  scrape_interval: 120s
  scrape_timeout: 60s
  http_sd_configs:
    - url: {{ .Values.atlas_url }}
  metrics_path: /ssh
  relabel_configs:
    - source_labels: [job]
      regex: network/ssh
      action: keep
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [credential]
      target_label: __param_credential
    - source_labels: [batch]
      target_label: __param_batch
    - source_labels: [device]
      target_label: __param_device
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: network-generic-ssh-exporter:9116
  metric_relabel_configs:
    - action: labeldrop
      regex: "metrics_label"
    - source_labels: [__name__, server_name]
      regex: '^ssh_[A-za-z0-9]+;.*((rt|asr)[0-9]+)[a|b]$'
      replacement: '$1'
      target_label: asr_pair
      action: replace
{{ end }}

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
