{{/*
Generic plugin name
*/}}
{{- define "release.name" -}}
{{- printf "%s" $.Release.Name | trunc 50 | trimSuffix "-" -}}
{{- end}}

{{/* Generate plugin specific labels */}}
{{- define "plugin.labels" -}}
plugindefinition: audit-logs
{{- if .Values.commonLabels }}
{{ tpl (toYaml .Values.commonLabels) . }}
{{- end }}
{{- end }}

{{/* Generate prometheus specific labels */}}
{{- define "plugin.prometheusLabels" }}
{{- if .Values.auditLogs.prometheus.additionalLabels }}
{{- tpl (toYaml .Values.auditLogs.prometheus.additionalLabels) . }}
{{- end }}
{{- if .Values.auditLogs.prometheus.rules.labels }}
{{ tpl (toYaml .Values.auditLogs.prometheus.rules.labels) . }}
{{- end }}
{{- end }}

{{/* Generate prometheus rule labels for alerts */}}
{{- define "plugin.additionalRuleLabels" -}}
{{- if .Values.auditLogs.prometheus.rules.additionalRuleLabels }}
{{- tpl (toYaml .Values.auditLogs.prometheus.rules.additionalRuleLabels) . }}
{{- end }}
{{- end }}
