{{/* Generate the full name. */}}
{{- define "fullName" -}}
{{- required ".Values.arista_exporter.name missing" .Values.arista_exporter.name -}}
{{- end -}}
