{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- if $root.Values.ruler.alertmanagers.hosts }}
alertmanagers:
  - scheme: https
    timeout: 10s
    api_version: v2
    {{- if $root.Values.ruler.alertmanagers.authentication.enabled }}
    http_config:
      tls_config:
        cert_file: /etc/thanos/secrets/{{ include "thanos.fullName" . }}-ruler-alertmanager-sso-cert/sso.crt
        key_file: /etc/thanos/secrets/{{ include "thanos.fullName" . }}-ruler-alertmanager-sso-cert/sso.key
    {{- end }}
    static_configs:
{{ toYaml $root.Values.ruler.alertmanagers.hosts | indent 8 }}
{{- end }}
