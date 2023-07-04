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
{{ .Values.rate_limit.blacklist | toYaml | indent 3 }}
{{- end }}

{{- if .Values.rate_limit.blacklist_users }}
#Blocked Users List
blacklist_users:
{{ .Values.rate_limit.blacklist_users | toYaml | indent 3 }}
{{- end }}

{{- if .Values.rate_limit.groups }}
#Custom groups for CADF actions
groups:
{{- range $group_name, $group_actions := .Values.rate_limit.groups }}
   {{ $group_name }}:
       {{- range $actions := $group_actions }}
      - {{ $actions }}
         {{- end }}
{{- end }}
{{- end }}

{{- if .Values.rate_limit.limit_by }}
{{- end }}

{{- if .Values.rate_limit.rates }}
rates:
{{- range $level_k, $level := .Values.rate_limit.rates }}
  {{ $level_k }}:
        {{- range $target_uri_type, $target_uri_type_limits := $level }}
    {{ $target_uri_type }}:
{{ $target_uri_type_limits | toYaml | indent 6 }}
        {{- end }}
{{- end }}
{{- end }}
