# customdns.yaml
{{- if .Values.customdns.matches }}
matches:
{{ .Values.customdns.matches | toYaml | indent 2}}
{{- end }}
