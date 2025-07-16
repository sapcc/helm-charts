{{- define "perses.labels" -}}
plugindefinition: perses
plugin: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.global.commonLabels }}
{{ tpl (toYaml .Values.global.commonLabels) . }}
{{- end }}
{{- end }}


{{- define "release.name" -}}
{{- printf "%s" $.Release.Name | trunc 50 | trimSuffix "-" -}}
{{- end}}

{{- define "perses.alertLabels" -}}
{{- if not (empty .Values.alertLabels) }}
{{- toYaml .Values.alertLabels  -}}
{{- end }}
{{- end }}