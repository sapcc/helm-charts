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
