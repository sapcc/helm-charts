{{- define "volume-claims.accessMode" -}}
{{- if has .Values.global.region (list "eu-de-3" "qa-de-8") -}}
ReadWriteOnce
{{- else -}}
ReadWriteMany
{{- end -}}
{{- end -}}
