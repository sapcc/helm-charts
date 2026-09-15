{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "serviceFromLabelsOrDefault" -}}
"{{`{{ if $labels.label_ccloud_service }}{{ $labels.label_ccloud_service }}{{ else }}{{ if $labels.label_alert_service }}{{ $labels.label_alert_service }}{{ else }}`}}{{ . }}{{`{{ end }}{{ end }}`}}"
{{- end -}}

{{- define "supportGroupFromLabelsOrDefault" -}}
"{{`{{ if $labels.label_ccloud_support_group }}{{ $labels.label_ccloud_support_group }}{{ else }}`}}{{ required "default value is missing" . }}{{`{{ end }}`}}"
{{- end -}}
