{{- define "volume-claims.accessMode" -}}
{{- if has .Values.global.region (list "eu-de-3") -}}
ReadWriteOnce
{{- else -}}
ReadWriteMany
{{- end -}}
{{- end -}}
