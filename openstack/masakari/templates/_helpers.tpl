{{- define "db_name" -}}
"{{ .Values.mariadb.name }}-mariadb"
{{- end }}


{{- define "masakari_api_endpoint_host_public" -}}
masakari.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end }}
