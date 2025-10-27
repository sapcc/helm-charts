{{- define "redis.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name -}}
{{- end -}}

{{- if .Values.nameOverride }}
{{- fail "redis: The nameOverride option is no longer supported because we did not see it anyone needing it." }}
{{- end }}
