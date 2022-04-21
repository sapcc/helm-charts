{{- define "lg_conf" -}}
{{- $region := index . 0 -}}
{{- $lg_config := index . 1 -}}
DEBUG = False
LOG_FILE="/var/log/lg.log"
LOG_LEVEL="WARNING"

DOMAIN = "px.svc.kubernetes.{{ $region }}.cloud.sap"

BIND_IP = "0.0.0.0"
BIND_PORT = 80

PROXY = {
    {{ range $i, $domain := list "1" "2" -}}
    {{- range $service := list "1" "2" "3" -}}
    {{- range $instance := list "1" "2" -}}
    "{{ $region }}-pxrs-{{ $domain }}-s{{ $service }}-{{ $instance }}": {{ $lg_config.proxy_port }},
    {{ end -}}
    {{- end -}}
    {{- end -}}
}

SESSION_KEY = '{{ $lg_config.session_key }}'
{{- end }}