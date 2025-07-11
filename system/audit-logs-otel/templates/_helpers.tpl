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
{{- if .Values.openTelemetryPlugin.openTelemetry.prometheus.additionalLabels }}
{{- tpl (toYaml .Values.openTelemetryPlugin.openTelemetry.prometheus.additionalLabels) . }}
{{- end }}
{{- if .Values.openTelemetryPlugin.openTelemetry.prometheus.rules.labels }}
{{ tpl (toYaml .Values.openTelemetryPlugin.openTelemetry.prometheus.rules.labels) . }}
{{- end }}
{{- end }}

{{/* Generate prometheus rule labels for alerts */}}
{{- define "plugin.additionalRuleLabels" -}}
{{- if .Values.openTelemetryPlugin.openTelemetry.prometheus.rules.additionalRuleLabels }}
{{- tpl (toYaml .Values.openTelemetryPlugin.openTelemetry.prometheus.rules.additionalRuleLabels) . }}
{{- end }}
{{- end }}
