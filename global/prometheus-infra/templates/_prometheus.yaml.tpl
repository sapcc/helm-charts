- job_name: 'prometheus-regions-federation'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
      - '{__name__=~"^global:.+"}'
      - '{__name__=~"^probe_(dns|duration|http|success).*"}'
      - '{__name__=~"^elasticsearch_octobus_.+"}'
      - '{__name__=~"^elasticsearch_readonlyrest_.+"}'
      - '{__name__=~"^elasticsearch_rabbitmq_econnrefused_error_failed_doc_count"}'
      - '{__name__=~"^elasticsearch_rabbitmq_econnrefused_hits"}'
      - '{__name__=~"^elasticsearch_rabbitmq_timeout_error_doc_count"}'
      - '{__name__=~"^elasticsearch_rabbitmq_timeout_hits"}'
      - '{__name__=~"^elasticsearch_memcached_toozconnection_hits"}'
      - '{__name__=~"^elasticsearch_memcached_toozconnection_doc_count"}'
      - '{__name__=~"^elasticsearch_dbconnection_error_doc_count"}'
      - '{__name__=~"^elasticsearch_dbconnection_hits"}'
      - '{__name__=~"^elasticsearch_dboperational_hits"}'
      - '{__name__=~"^elasticsearch_dboperational_error_doc_count"}'
      - '{__name__=~"^elasticsearch_logstash_.+"}'
      - '{__name__=~"^elasticsearch_hermes_.+"}'
      - '{__name__=~"^elasticsearch_scaleout_.+"}'
      - '{__name__=~"^elasticsearch_kubernikus_.+"}'
      - '{__name__=~"^elasticsearch_jump_.+"}'
      - '{__name__=~"^neutron_router:.+"}'
      - '{__name__=~"^elasticsearch_openstack_glance.+"}'
      - '{__name__=~"^atlas_targets"}'
      - '{__name__=~"^atlas_sd_up"}'
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
      - '{__name__=~"^vasa_.*"}'
      - '{__name__=~"^vcenter_esxi_mem_swapout_.*"}'
      - '{__name__=~"^pxcloudprober_.+"}'
      - '{__name__=~"^thousandeyes_test_html_loss_percentage", test_name=~"[A-Z]{2}-[A-Z]{2}-[A-Z0-9]{2}.+"}'
      - '{__name__=~"^thousandeyes_test_html_avg_latency_milliseconds", test_name=~"[A-Z]{2}-[A-Z]{2}-[A-Z0-9]{2}.+"}'
      - '{__name__=~"^thousandeyes_test_html_response_code", test_name=~"[A-Z]{2}-[A-Z]{2}-[A-Z0-9]{2}.+"}'
      - '{__name__=~"^thousandeyes_requests_total"}'
      - '{__name__=~"^thousandeyes_requests_fails"}'
      - '{__name__=~"^ssh_(nx|xe)_ntp_configured"}'
      - '{__name__=~"^ssh_redundancy_state"}'
      - '{__name__=~"^ssh_xr_ntp_.+"}'
      - '{job="logs-fluent-exporter", __name__!~"^(fluentd_input_status_num_records_total|fluentd_output_status_num_records_total)"}'
      - '{__name__=~"^es_cluster_status"}'
      - '{__name__=~"^es_fs_path_.+"}'
      - '{__name__=~"^es_index_size_mb"}'
      - '{__name__=~"^es_index_store_size_bytes"}'
      - '{__name__=~"^es_fs_path_total_bytes"}'
      - '{__name__=~"^es_fs_path_available_bytes"}'
      - '{__name__=~"^filebeat_filebeat_input_netflow"}'
      - '{__name__=~"^fluentbit_.+"}'
      - '{__name__=~"^metis_.+"}'
      - '{__name__=~"^maria_backup_.+"}'
      - '{__name__=~"^logstash_node_queue_.+"}'
      - '{__name__=~"^logstash_node_pipeline_.+"}'
      - '{__name__=~"^logstash_node_mem_heap_used_bytes"}'
      - '{__name__=~"^logstash_node_plugin_events_in_total", plugin=~"elasticsearch|opensearch"}'
      - '{__name__=~"^logstash_node_plugin_events_out_total", plugin=~"elasticsearch|opensearch"}'
      - '{__name__=~"^opensearch_retention_.+"}'
      - '{__name__=~"^opensearch_cluster_status"}'
      - '{__name__=~"^opensearch_index_size_mb"}'
      - '{__name__=~"^logstash_node_plugin_failures_total", plugin=~"elasticsearch|opensearch"}'
      - '{__name__=~"^vcsa_service_status"}'
      - '{__name__=~"^windows_updates_.+"}'
      - '{__name__=~"^windows_ad_certificate_.+"}'
      - '{__name__=~"^aws_ses_cronus_.+"}'
      - '{__name__=~"^cronus_simulator_.+"}'
      - '{__name__=~"^cronus_updater_.+"}'
      - '{__name__=~"^network_apic_(free|used|down)_port_count"}'
      - '{__name__=~"^prom_fluentd_.+"}'
      - '{job="netbox", __name__!~"^(up|ALERTS.*|scrape.+)"}'
      - '{__name__=~"^cc3test_status", service="ironic", type="baremetal_and_regression"}'

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

- job_name: 'prometheus-regions-snmp-federation'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s

  honor_labels: true
  metrics_path: '/federate'

  params:
    'match[]':
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
      - '{__name__=~"^snmp_coreasr9k_sysDescr"}'
      - '{__name__=~"^snmp_aristaevpn_sysDescr"}'
      - '{__name__=~"^snmp_n3k_sysDescr"}'
      - '{__name__=~"^snmp_pxgeneric_sysDescr"}'
      - '{__name__=~"^snmp_pxgeneric_rttMon.+"}'
      - '{__name__=~"^snmp_pxgeneric_ifHC(In|Out)Octets.+", role="directlink-router"}'
      - '{__name__=~"^snmp_n9kpx_ciscoImageString"}'
      - '{__name__=~"^snmp_ipn_sysDescr"}'
      - '{__name__=~"^snmp_acispine_sysDescr"}'
      - '{__name__=~"^snmp_acileaf_sysDescr"}'
      - '{__name__=~"^snmp_acistretch_sysDescr"}'
      - '{__name__=~"^snmp_arista_entPhysicalSoftwareRev"}'
      - '{__name__=~"^snmp_f5_sysProductVersion"}'
      - '{__name__=~"^snmp_asa_sysDescr"}'
      - '{__name__=~"^snmp_scrape.+"}'
      - '{__name__=~"^snmp_apod_asa_sysDescr"}'
      - '{__name__=~"^snmp_apod_arista_devices"}'
      - '{__name__=~"^snmp_apod_asr_devices"}'
      - '{__name__=~"^snmp_apod_coreasr9k_sysDescr"}'
      - '{__name__=~"^snmp_apod_f5_sysName"}'
      - '{__name__=~"^snmp_apod_ipn_sysDescr"}'
      - '{__name__=~"^snmp_apod_n3k_sysDescr"}'
      - '{__name__=~"^snmp_apod_ucs_sysDescr"}'
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
