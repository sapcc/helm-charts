- scheme: https
  timeout: 10s
  {{ if .Values.alertmanagers.authentication.enabled -}}
  tls_config:
    cert_file: /etc/prometheus/secrets/{{ include "prometheus.fullName" . }}-alertmanager-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/{{ include "prometheus.fullName" . }}-alertmanager-sso-cert/sso.key
  {{- end }}

  static_configs:
    - targets:
{{ toYaml .Values.alertmanagers.hosts | indent 8 }}

  # Ensure alerts always have the necessary labels set to identify them.
  relabel_configs:
    - action: replace
      target_label: region
      replacement: {{ required ".Values.global.region missing" .Values.global.region }}
    - action: replace
      target_label: cluster_type
      replacement: {{ required ".Values.global.clusterType missing" .Values.global.clusterType }}
    - action: replace
      target_label: cluster
      replacement: {{ if .Values.global.cluster }}{{ .Values.global.cluster }}{{ else }}{{ .Values.global.region }}{{ end }}
