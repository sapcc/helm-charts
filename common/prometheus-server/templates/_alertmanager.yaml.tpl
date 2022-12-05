{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if $root.Values.alertmanagers.hosts }}
- scheme: https
  timeout: 10s
  {{ if $root.Values.alertmanagers.authentication.enabled -}}
  tls_config:
    cert_file: /etc/prometheus/secrets/{{ include "prometheus.fullName" . }}-alertmanager-sso-cert/sso.crt
    key_file: /etc/prometheus/secrets/{{ include "prometheus.fullName" . }}-alertmanager-sso-cert/sso.key
  {{- end }}

  static_configs:
    - targets:
{{ toYaml $root.Values.alertmanagers.hosts | indent 8 }}
{{- end }}
