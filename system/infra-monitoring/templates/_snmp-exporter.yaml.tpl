- job_name: 'snmp-exporter-arista'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /etc/prometheus/config/snmp_exporter_targets.json
  metrics_path: /snmp
  params:
      module: [arista]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter.{{ .Values.global.region }}.{{ .Values.global.domain }}
- job_name: 'snmp-exporter-asa'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /etc/prometheus/config/snmp_exporter_targets.json
  metrics_path: /snmp
  params:
      module: [asa]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter.{{ .Values.global.region }}.{{ .Values.global.domain }}
- job_name: 'snmp-exporter-asr'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /etc/prometheus/config/snmp_exporter_targets.json
  metrics_path: /snmp
  params:
      module: [asr]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter.{{ .Values.global.region }}.{{ .Values.global.domain }}
- job_name: 'snmp-exporter-asr04'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /etc/prometheus/config/snmp_exporter_targets.json
  metrics_path: /snmp
  params:
      module: [asr04]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter.{{ .Values.global.region }}.{{ .Values.global.domain }}
- job_name: 'snmp-exporter-f5'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /etc/prometheus/config/snmp_exporter_targets.json
  metrics_path: /snmp
  params:
      module: [f5]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter.{{ .Values.global.region }}.{{ .Values.global.domain }}
- job_name: 'snmp-exporter-n7k'
  scheme: https
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /etc/prometheus/config/snmp_exporter_targets.json
  metrics_path: /snmp
  params:
      module: [n7k]
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter.{{ .Values.global.region }}.{{ .Values.global.domain }}
