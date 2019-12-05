- job_name: 'metal-federation'
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
      source_labels: [region]
      target_label: cluster
    - action: replace
      target_label: cluster_type
      replacement: metal

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
      source_labels: [region]
      regex: (.*)
      target_label: cluster
      replacement: s-$1
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
{{- range $region := without .Values.regionList "admin" "staging" }}
      - "prometheus-kubernetes.scaleout.{{ $region }}.cloud.sap"
{{- end }}

- job_name: 'internet-federation'
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
      source_labels: [region]
      regex: (.*)
      target_label: cluster
      replacement: i-$1
    - action: replace
      target_label: cluster_type
      replacement: internet

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

- job_name: 'customer-federation'
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
      source_labels: [region]
      regex: (.*)
      target_label: cluster
      replacement: c-$1
    - action: replace
      target_label: cluster_type
      replacement: customer

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
      - "prometheus.customer.eu-de-2.cloud.sap"

- job_name: 'abapcloud-federation'
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
      source_labels: [region]
      regex: (.*)
      target_label: cluster
      replacement: a-$1
    - action: replace
      target_label: cluster_type
      replacement: abapcloud

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
      - "prometheus.abapcloud.eu-nl-1.cloud.sap"

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
      source_labels: [region]
      regex: (.*)
      target_label: cluster
      replacement: v-$1
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
        - prometheus.virtual.ap-jp-2.cloud.sap
