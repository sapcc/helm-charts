{{- define "chart" -}}
{{- printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "name" -}}
{{- "schedules2slack" -}}
{{- end -}}
