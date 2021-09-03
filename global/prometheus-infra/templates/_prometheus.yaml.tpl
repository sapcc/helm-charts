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
      - '{__name__=~"^elasticsearch_octobus_.+"}'
      - '{__name__=~"^snmp_asa_.+"}'
      - '{__name__=~"^snmp_asr_nat.+"}'
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
      - '{__name__=~"^snmp_asr04_ntpEntStatusActiveOffset"}'
      - '{__name__=~"^snmp_asr04_ntpEntStatusDispersion"}'
      - '{__name__=~"^elasticsearch_openstack_glance.+"}'
      - '{__name__=~"^snmp_n3k_sysDescr"}'
      - '{__name__=~"^snmp_n7k_sysDescr"}'
      - '{__name__=~"^snmp_n7k_cntpSysRootDelay"}'
      - '{__name__=~"^snmp_n7k_cntpSysRootDispersion"}'
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
      - '{__name__=~"snmp_f5_sysMultiHostCpuUsageRatio1m"}'
      - '{__name__=~"snmp_f5_ltmVirtualAddrNumber"}'
      - '{__name__=~"snmp_f5_ltmVirtualServNumber"}'
      - '{__name__=~"snmp_f5_ltmPoolNumber"}'
      - '{__name__=~"snmp_f5_ltmPoolMemberCnt"}'
      - '{__name__=~"snmp_f5_ltmNodeAddrNumber"}'
      - '{__name__=~"snmp_f5_ltmTransAddrNumber"}'
      - '{__name__=~"snmp_f5_ltmVirtualAddrName"}'
      - '{__name__=~"^ssh_nat.+"}'
      - '{__name__=~"^vcenter_vcenter.*"}'
      - '{__name__=~"^vcenter_esx.*"}'
      - '{__name__=~"^ping_.+"}'
      - '{__name__=~"^cloudprober_.+"}'
      - '{__name__=~"^ipmi_sensor_state$",type=~"Memory|Drive Slot|Processor|Power Supply|Critical Interrupt|Version Change|Event Logging Disabled|System Event"}'
      - '{__name__=~"^ipmi_memory_.+"}'
      - '{__name__=~"^vcenter_prod_cluster"}'
      - '{__name__=~"^vcenter_failover_host"}'
      - '{__name__=~"^vcenter_vms_on_failover_hosts"}'
      - '{__name__=~"^vcenter_overbooked_node_mb"}'
      - '{__name__=~"^up"}'
      - '{__name__=~"^ipmi_up"}'
      - '{__name__=~"^redfish_.+"}'
      - '{__name__=~"^ucsm_.+"}'
      - '{__name__=~"^netapp_aggregate_.*"}'
      - '{__name__=~"^netapp_filer_.*"}'
      - '{__name__=~"^vasa_.*"}'
      - '{__name__=~"^vcenter_esxi_mem_swapout_.*"}'
      - '{__name__=~"^bios_exporter",setting_name=~"memory_memorymode|biosvfselectmemoryrasconfiguration|memory_ras_configuration|bios_memsettings_adddcsetting|bios_memsettings_memopmode"}'
      - '{__name__=~"^bios_exporter_up"}'
      - '{__name__=~"^pxcloudprober_.+"}'
      - '{__name__=~"^cablecheck_error_status"}'
      - '{__name__=~"^cablecheck_runs_counter_total"}'
      - '{__name__=~"^thousandeyes_test_html_loss_percentage", test_name=~"[A-Z]{2}-[A-Z]{2}-[A-Z0-9]{2}.+"}'
      - '{__name__=~"^thousandeyes_test_html_avg_latency_milliseconds", test_name=~"[A-Z]{2}-[A-Z]{2}-[A-Z0-9]{2}.+"}'
      - '{__name__=~"^thousandeyes_test_html_response_code", test_name=~"[A-Z]{2}-[A-Z]{2}-[A-Z0-9]{2}.+"}'
      - '{__name__=~"^thousandeyes_requests_total"}'
      - '{__name__=~"^thousandeyes_requests_fails"}'
      - '{__name__=~"^ssh_(nx|xe)_ntp_configured"}'
      - '{__name__=~"^ssh_redundancy_state"}'
      - '{__name__=~"^fluentd_.+"}'
      - '{__name__=~"^es_cluster_status"}'
      - '{__name__=~"^es_fs_path_.+"}'
      - '{__name__=~"^es_index_size_mb"}'
      - '{__name__=~"^es_index_store_size_bytes"}'
      - '{__name__=~"^es_fs_path_total_bytes"}'
      - '{__name__=~"^es_fs_path_available_bytes"}'
      - '{__name__=~"elastiflow_thousandeyes_probes_hits"}'
      - '{__name__=~"^logstash_node_queue_.+"}'
      - '{__name__=~"^logstash_node_pipeline_.+"}'
      - '{__name__=~"^vcsa_service_status"}'
      - '{__name__=~"^windows_updates_.+"}'
      - '{__name__=~"^aws_ses_cronus_provider_.+"}'
      - '{__name__=~"^cronus_simulator_.+"}'
      - '{__name__=~"^cronus_updater_.+"}'
      - '{__name__=~"^network_apic_(free|used|down)_port_count"}'

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

- job_name: 'prometheus-regions-vrops-federation'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{__name__=~"^vrops_api_response"}'
      - '{__name__=~"^vrops_inventory_collection_time_seconds"}'
      - '{__name__=~"^vrops_inventory_iteration_total"}'
      - '{__name__=~"^vrops_vcenter_cpu_used_percent"}'
      - '{__name__=~"^vrops_vcenter_memory_used_percent"}'
      - '{__name__=~"^vrops_vcenter_diskspace_total_gigabytes"}'
      - '{__name__=~"^vrops_vcenter_diskspace_usage_gigabytes"}'
      - '{__name__=~"^vrops_vcenter_vcsa_certificate_remaining_days"}'
      - '{__name__=~"^vrops_vcenter_summary_version_info"}'
      - '{__name__=~"^vrops_cluster_cluster_running_hosts"}'
      - '{__name__=~"^vrops_cluster_configuration_drsconfig_targetbalance"}'
      - '{__name__=~"^vrops_cluster_cpu_capacity_mhz"}'
      - '{__name__=~"^vrops_cluster_cpu_capacity_usage_percentage"}'
      - '{__name__=~"^vrops_cluster_cpu_contention_percentage"}'
      - '{__name__=~"^vrops_cluster_memory_capacity_kilobytes"}'
      - '{__name__=~"^vrops_cluster_memory_usage_percentage"}'
      - '{__name__=~"^vrops_cluster_services_totalimbalance"}'
      - '{__name__=~"^vrops_hostsystem_cpu_usage_average_percentage"}'
      - '{__name__=~"^vrops_hostsystem_cpu_sockets_number"}'
      - '{__name__=~"^vrops_hostsystem_cpu_usage_megahertz"}'
      - '{__name__=~"^vrops_hostsystem_custom_attributes_hw_info"}'
      - '{__name__=~"^vrops_hostsystem_memory_ballooning_kilobytes"}'
      - '{__name__=~"^vrops_hostsystem_memory_host_usage_kilobytes"}'
      - '{__name__=~"^vrops_hostsystem_memory_usage_percentage"}'
      - '{__name__=~"^vrops_hostsystem_memory_swap_out_rate_kbps"}'
      - '{__name__=~"^vrops_hostsystem_memory_swap_used_rate_kbps"}'
      - '{__name__=~"^vrops_hostsystem_summary_number_vms_total"}'
      - '{__name__=~"^vrops_hostsystem_summary_version_info"}'
      - '{__name__=~"^vrops_hostsystem_summary_number_vmotion_total"}'
      - '{__name__=~"^vrops_hostsystem_runtime_maintenancestate", state="inMaintenance"}'
      - '{__name__=~"^vrops_hostsystem_runtime_connectionstate"}'
      - '{__name__=~"^vrops_hostsystem_runtime_powerstate"}'
      - '{__name__=~"^vrops_hostsystem_configuration_dasconfig_admissioncontrolpolicy_failoverhost"}'
      - '{__name__=~"^vrops_hostsystem_hardware_bios_version"}'
      - '{__name__=~"^vrops_hostsystem_hardware_model"}'
      - '{__name__=~"^vrops_virtualmachine_memory_usage_average"}'
      - '{__name__=~"^vrops_virtualmachine_memory_kilobytes"}'
      - '{__name__=~"^vrops_virtualmachine_number_vcpus_total"}'
      - '{__name__=~"^vrops_virtualmachine_config_hardware_memory_kilobytes"}'
      - '{__name__=~"^vrops_virtualmachine_summary_ethernetcards"}'
      - '{__name__=~"^vrops_virtualmachine_runtime_connectionstate",state="disconnected"}'
      - '{__name__=~"^vrops_virtualmachine_runtime_powerstate"}'
      - '{__name__=~"^vrops_datastore_.+", type!~"local"}'
      - '{__name__=~"^vrops_nsxt.*"}'

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
