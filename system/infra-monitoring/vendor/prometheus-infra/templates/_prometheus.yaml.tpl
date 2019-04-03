rule_files:
  - ./*.rules

global:
  scrape_timeout: 55s

scrape_configs:
{{- if .Values.arista_snmp_exporter.enabled }}
- job_name: 'arista-{{ .Values.global.region }}'
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /custom_targets/snmp/arista_targets.json
  params:
      module: [arista]
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:9116
{{- end }}
{{- if .Values.asr04_snmp_exporter.enabled }}
- job_name: 'asr04-{{ .Values.global.region }}'
  scrape_interval: 60s
  scrape_timeout: 55s
  file_sd_configs:
      - files :
        - /custom_targets/snmp/asr04_targets.json
  params:
      module: [asr04]
  metrics_path: /snmp
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: snmp-exporter:9116
{{- end }}
