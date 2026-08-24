{{- define "helm3-helper.annotations" -}}
meta.helm.sh/release-name: {{ .Release.Name }}
meta.helm.sh/release-namespace: {{ .Release.Namespace }}
{{- end -}}

{{- define "helm3-helper.labels" -}}
app.kubernetes.io/managed-by: Helm
{{- end -}}
