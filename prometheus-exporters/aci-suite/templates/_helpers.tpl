{{- define "aci-suite.secretName" -}}
{{- if .Values.global.auth.existingSecret -}}
{{- .Values.global.auth.existingSecret -}}
{{- else -}}
{{- printf "%s-global-secret" .Release.Name -}}
{{- end -}}
{{- end -}}

{{- define "aci-suite.labels" -}}
app.kubernetes.io/part-of: aci-suite
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
