- job_name: 'controlplane-federation'
  scheme: https
  scrape_interval: 30s
  scrape_timeout: 25s

  honor_labels: true
  metrics_path: '/federate'

{{ include "prometheus.federatedMetricsConfig" .Values.allowedMetrics | indent 2 }}

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: prometheus-kubernetes.(.+).cloud.sap
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

  {{ if .Values.authentication.enabled }}
  tls_config:
    cert_file: /etc/prometheus/secrets/prometheus-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/prometheus-sso-cert/sso.key
  {{ end }}

  static_configs:
    - targets:
{{- range $region := .Values.regionList }}
      - "prometheus-kubernetes.{{ $region }}.cloud.sap"
{{- end }}

- job_name: 'scaleout-federation'
  scheme: https
  scrape_interval: 30s
  scrape_timeout: 25s

  honor_labels: true
  metrics_path: '/federate'

{{ include "prometheus.federatedMetricsConfig" .Values.allowedMetrics | indent 2 }}

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: .+\.(.+).cloud.sap
      replacement: $1

    - action: replace
      target_label: cluster_type
      replacement: scaleout

  metric_relabel_configs:
    - action: replace
      source_labels: [__name__]
      target_label: __name__
      regex: global:(.+)
      replacement: $1

  {{ if .Values.authentication.enabled }}
  tls_config:
    cert_file: /etc/prometheus/secrets/prometheus-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/prometheus-sso-cert/sso.key
  {{ end }}

  static_configs:
    - targets:
      - "prometheus.internet.eu-de-2.cloud.sap"
      - "prometheus.kubernetes-ccloudshell.eu-de-2.cloud.sap"
{{- range $region := without .Values.regionList "admin" "staging" }}
      - "prometheus-kubernetes.scaleout.{{ $region }}.cloud.sap"
{{- end }}

- job_name: 'virtual-federation'
  scheme: https
  scrape_interval: 30s
  scrape_timeout: 25s

  honor_labels: true
  metrics_path: '/federate'

{{ include "prometheus.federatedMetricsConfig" .Values.allowedMetrics | indent 2 }}

  relabel_configs:
    - action: replace
      source_labels: [__address__]
      target_label: region
      regex: .+\.(.+).cloud.sap
      replacement: $1

    - action: replace
      target_label: cluster_type
      replacement: virtual

  metric_relabel_configs:
    - action: replace
      source_labels: [__name__]
      target_label: __name__
      regex: global:(.+)
      replacement: $1

  {{ if .Values.authentication.enabled }}
  tls_config:
    cert_file: /etc/prometheus/secrets/prometheus-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/prometheus-sso-cert/sso.key
  {{ end }}

  static_configs:
    - targets:
        - prometheus.virtual.qa-de-1.cloud.sap
{{- end }}
