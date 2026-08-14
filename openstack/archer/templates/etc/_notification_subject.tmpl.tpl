{{ `{{- if eq .Type "immediate" -}}` }}
[ACTION] Archer Endpoint Services: New endpoint(s) pending approval
{{ `{{- else -}}` }}
[ACTION] Archer Endpoint Services: {{ `{{ .TotalEndpoints }}` }} endpoint(s) awaiting approval
{{ `{{- end -}}` }}
