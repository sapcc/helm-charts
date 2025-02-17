#Allowed Projects List
{{- if .Values.rate_limit.whitelist }}
whitelist:
{{ .Values.rate_limit.whitelist | toYaml | indent 3 }}
{{- end }}

{{- if .Values.rate_limit.whitelist_users }}
#Allowed Users List
whitelist_users:
{{ .Values.rate_limit.whitelist_users | toYaml | indent 3 }}
{{- end }}

{{- if .Values.rate_limit.blacklist }}
#Blocked Projects List
blacklist:
{{ .Values.rate_limit.blacklist | toYaml | indent 2 }}
{{- end }}

{{- if .Values.rate_limit.blacklist_users }}
#Blocked Users List
blacklist_users:
{{ .Values.rate_limit.blacklist_users | toYaml | indent 2 }}
{{- end }}

{{- if .Values.rate_limit.groups }}
#Custom groups for CADF actions
groups:
{{ .Values.rate_limit.groups | toYaml | indent 2 }}
{{- end }}
{{- if .Values.rate_limit.rates }}
rates:
{{ .Values.rate_limit.rates | toYaml | indent 2 }}
{{- end }}
