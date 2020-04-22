- job_name: 'prometheus-regions-federation'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{__name__=~"^ALERTS$"}'
      - '{__name__=~"^global:.+"}'
      - '{__name__=~"^probe_(dns|duration|http|success).*"}'
      - '{__name__=~"^snmp_asa_.+"}'
      - '{__name__=~"^snmp_asr_nat.+"}'
      - '{__name__=~"^snmp_asr_disman.+"}'
      - '{__name__=~"^snmp_asr_sysDescr"}'
      - '{__name__=~"^snmp_asr03_sysDescr"}'
      - '{__name__=~"^snmp_asr03_rttMonLatestRttOperCompletionTime"}'
      - '{__name__=~"^snmp_asr03_rttMonLatestRttOperSense"}'
      - '{__name__=~"^snmp_asr03_rttMonLatestRttOperTime"}'
      - '{__name__=~"^snmp_asr03_rttMonJitterStatsCompletions"}'
      - '{__name__=~"^snmp_asr03_rttMonJitterStatsPacketLossSD"}'
      - '{__name__=~"^snmp_asr03_rttMonJitterStatsPacketLossDS"}'
      - '{__name__=~"^snmp_asr03_rttMonJitterStatsPacketOutOfSequence"}'
      - '{__name__=~"^snmp_asr04_sysDescr"}'
      - '{__name__=~"^snmp_n3k_sysDescr"}'
      - '{__name__=~"^snmp_n7k_sysDescr"}'
      - '{__name__=~"^snmp_pxdlrouternxos_sysDescr"}'
      - '{__name__=~"^snmp_pxdlrouternxos_rttMon.+"}'
      - '{__name__=~"^snmp_pxdlrouternxos_if.+"}'
      - '{__name__=~"^snmp_n9kpx_ciscoImageString"}'
      - '{__name__=~"^snmp_ipn_sysDescr"}'
      - '{__name__=~"^snmp_acispine_sysDescr"}'
      - '{__name__=~"^snmp_acistretch_sysDescr"}'
      - '{__name__=~"^snmp_arista_entPhysicalSoftwareRev"}'
      - '{__name__=~"^snmp_f5_sysProductVersion"}'
      - '{__name__=~"^snmp_asa_sysDescr"}'
      - '{__name__=~"^snmp_scrape.+"}'
      - '{__name__=~"^elasticsearch_snmp_reason_module_ip_doc_count"}'
      - '{__name__=~"^atlas_targets"}'
      - '{__name__=~"^atlas_sd_up"}'
      - '{__name__=~"snmp_f5_sysMultiHostCpuUsageRatio5s"}'
      - '{__name__=~"snmp_f5_sysGlobalHostOtherMemUsedKb"}'
      - '{__name__=~"snmp_f5_sysGlobalHostOtherMemTotalKb"}'
      - '{__name__=~"snmp_f5_sysGlobalTmmStatMemoryUsedKb"}'
      - '{__name__=~"snmp_f5_sysGlobalTmmStatMemoryTotalKb"}'
      - '{__name__=~"snmp_f5_sysGlobalHostSwapUsedKb"}'
      - '{__name__=~"snmp_f5_sysGlobalHostSwapTotalKb"}'
      - '{__name__=~"snmp_f5_ltmVirtualAddrNumber"}'
      - '{__name__=~"snmp_f5_ltmVirtualServNumber"}'
      - '{__name__=~"snmp_f5_ltmPoolNumber"}'
      - '{__name__=~"snmp_f5_ltmPoolMemberCnt"}'
      - '{__name__=~"snmp_f5_ltmNodeAddrNumber"}'
      - '{__name__=~"snmp_f5_ltmTransAddrNumber"}'
      - '{__name__=~"snmp_f5_ltmVirtualAddrName"}'
      - '{__name__=~"^vcenter_vcenter.*"}'
      - '{__name__=~"^vcenter_esx.*"}'
      - '{__name__=~"^ping_.+"}'
      - '{__name__=~"^cloudprober_.+"}'
      - '{__name__=~"^ipmi_sensor_state$",type=~"Memory|Drive Slot|Processor|Power Supply|Critical Interrupt|Version Change|Event Logging Disabled|System Event"}'
      - '{__name__=~"^ipmi_memory_errors$"}'
      - '{__name__=~"^vcenter_prod_cluster"}'
      - '{__name__=~"^vcenter_failover_host"}'
      - '{__name__=~"^vcenter_vms_on_failover_hosts"}'
      - '{__name__=~"^vcenter_overbooked_node_mb"}'
      - '{__name__=~"^up"}'
      - '{__name__=~"^ipmi_up"}'
      - '{__name__=~"^redfish_.+"}'
      - '{__name__=~"^netapp_capacity_aggregate"}'
      - '{__name__=~"^netapp_aggregate_.*"}'
      - '{__name__=~"^netapp_filer_.*"}'
      - '{__name__=~"^vasa_.*"}'
      - '{__name__=~"^vcenter_esxi_mem_swapout_.*"}'
      - '{__name__=~"^bios_exporter",setting_name=~"memory_memorymode|biosvfselectmemoryrasconfiguration|memory_ras_configuration|bios_memsettings_adddcsetting|bios_memsettings_memopmode"}'
      - '{__name__=~"^bios_exporter_up"}'
      - '{__name__=~"^pxcloudprober_.+"}'
      - '{__name__=~"^vrops_datastore_stats",datastore!~"^node.+"}'
      - '{__name__=~"^cablecheck_error_status"}'
      - '{__name__=~"^cablecheck_error_status_vpods"}'
      - '{__name__=~"^thousandeyes_test_html_loss_percentage"}'
      - '{__name__=~"^thousandeyes_test_html_avg_latency_milliseconds"}'
      - '{__name__=~"^thousandeyes_requests_total"}'
      - '{__name__=~"^thousandeyes_requests_fails"}'

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: prometheus-infra.scaleout.(.+).cloud.sap
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
    - source_labels: [__name__, prometheus_source, prometheus]
      regex: '^up;^$;(.+)'
      replacement: '$1'
      target_label: prometheus_source
      action: replace

  {{ if .Values.authentication.enabled }}
  tls_config:
    cert_file: /etc/prometheus/secrets/prometheus-infra-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/prometheus-infra-sso-cert/sso.key
  {{ end }}

  static_configs:
    - targets:
{{- range $region := .Values.regionList }}
      - "prometheus-infra.scaleout.{{ $region }}.cloud.sap"
{{- end }}
