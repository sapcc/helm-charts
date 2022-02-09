{{- define "httpBasicAuth"}}
{{- printf "%s:%s" .Values.global.elk_elasticsearch_http_user .Values.global.elk_elasticsearch_http_password | b64enc }}
{{- end }}
