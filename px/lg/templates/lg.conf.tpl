{{- define "lg_conf" -}}
DEBUG = False
LOG_FILE="/var/log/lg.log"
LOG_LEVEL="WARNING"

DOMAIN = "px.svc"

BIND_IP = "0.0.0.0"
BIND_PORT = 80

PROXY = {
    {{ range $i, $domain := list "1" "2" -}}
    {{- range $service := list "1" "2" "3" -}}
    {{- range $instance := list "1" "2" -}}
    "routeserver-v4-service-{{ $service }}-domain-{{ $domain }}-{{ $instance }}": {{ $.proxy_port }},
    {{ end -}}
    {{- end -}}
    {{- end -}}
}

SESSION_KEY = '{{ .session_key }}'
{{- end }}
