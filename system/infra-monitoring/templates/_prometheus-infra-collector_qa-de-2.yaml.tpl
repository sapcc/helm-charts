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
    - source_labels: [__name__]
      regex: '!arista_port_stats'
      action: keep
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: arista-exporter:9200
{{- end }}

- job_name: 'snmp_ucs'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=ucs&model=ucs-fi-6332-16up&manufacturer=cisco&status=active&region={{ .Values.global.region }}
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_aristaevpn'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=evpn-arista&manufacturer=arista&status=active&region={{ .Values.global.region }}&role=evpn-leaf&target=loopback10
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_hsm'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=hsm&manufacturer=thales&status=active&region={{ .Values.global.region }}&role=hsm
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_acileaf_gmp'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=acileaf&manufacturer=cisco&status=active&region={{ .Values.global.region }}&role=aci-leaf&tenant=cnd-gmponaci
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_acileaf_cc'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=acileaf&manufacturer=cisco&status=active&region={{ .Values.global.region }}&role=aci-leaf&tenant=converged-cloud
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_ipn'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=ipn&manufacturer=cisco&status=active&region={{ .Values.global.region }}&role=aci-ipn
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_acispine'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=acispine&manufacturer=cisco&status=active&region={{ .Values.global.region }}&role=aci-spine
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_acistretch'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=acistretch&manufacturer=cisco&status=active&region={{ .Values.global.region }}&role=aci-stretch
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_f5customer'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=f5customer&manufacturer=f5&status=active&region={{ .Values.global.region }}&tag=cc-net-f5-guest-lbaas
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_f5mgmt'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=f5mgmt&manufacturer=f5&status=active&region={{ .Values.global.region }}&tag=cc-net-f5-guest-mgmt
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_f5gtm'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=f5gtm&manufacturer=f5&status=active&region={{ .Values.global.region }}&model=f5-vcmp&q=gtm
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_f5physical'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=f5physical&manufacturer=f5&status=active&region={{ .Values.global.region }}&tag=cc-net-f5-host
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_asr03'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=asr03&manufacturer=cisco&status=active&region={{ .Values.global.region }}&q=asr03
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_coreasr9k'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=coreasr9k&manufacturer=cisco&status=active&region={{ .Values.global.region }}&role=core-router&tenant=cnd-netbb&platform=cisco-ios-xr
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_asr'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=asr&manufacturer=cisco&status=active&region={{ .Values.global.region }}&role=neutron-router
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_asw'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=asw&manufacturer=arista&status=active&region={{ .Values.global.region }}&q=asw2
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_asw9'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=asw9&manufacturer=arista&status=active&region={{ .Values.global.region }}&q=asw9
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_n9kpx'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=n9kpx&status=active&region={{ .Values.global.region }}&role=px-switch
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_pxdlrouteriosxe'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=pxdlrouteriosxe&platform=cisco-ios-xe&status=active&region={{ .Values.global.region }}&role=directlink-router
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_pxdlrouteriosxr'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=pxdlrouteriosxr&platform=cisco-ios-xr&status=active&region={{ .Values.global.region }}&role=directlink-router
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_pxdlroutergeneric'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=pxdlroutergeneric&status=active&region={{ .Values.global.region }}&role=directlink-router
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_pxgeneric'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=pxgeneric&status=active&region={{ .Values.global.region }}&tenant=cnd-px
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_n3k'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/devices/?custom_labels=__param_module=n3k&manufacturer=cisco&status=active&region={{ .Values.global.region }}&tenant=converged-cloud&role=management-switch
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_asa'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/virtual-machines/?custom_labels=__param_module=asa&status=active&q={{ .Values.global.region }}&tenant=cnd&role=management-switch&platform=cisco-asa
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

- job_name: 'snmp_fortinet'
  scrape_interval: {{.Values.snmp_exporter.scrapeInterval}}
  scrape_timeout: {{.Values.snmp_exporter.scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.http_sd_configs.netbox_staging_url }}/virtual-machines/?custom_labels=__param_module=fortinet&status=active&q={{ .Values.global.region }}&manufacturer=fortinet&role=firewall
      refresh_interval: {{ .Values.http_sd_configs.refresh_interval }}
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:{{.Values.snmp_exporter.listen_port}}
{{ include "snmp_metric_relabel_configs" . | indent 2 }}

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
    - source_labels: [__name__]
      regex: '!ipmi_temperature_state'
      action: keep
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
    - source_labels: [__name__]
      regex: '!redfish_health'
      action: keep
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

{{- if $values.firmware.enabled }}
- job_name: 'redfish_fw'
  params:
    job: [redfish_fw]
  scrape_interval: {{$values.redfish_fw_scrapeInterval}}
  scrape_timeout: {{$values.redfish_fw_scrapeTimeout}}
  http_sd_configs:
    - url: {{ .Values.atlas_url }}
  metrics_path: /firmware
  relabel_configs:
    - source_labels: [job]
      regex: redfish_fw
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
