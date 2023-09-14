{{/* Generate the full name. */}}
{{- define "fullName" -}}
{{- required ".Values.redfish_exporter.name missing" .Values.redfish_exporter.name -}}
{{- end -}}
