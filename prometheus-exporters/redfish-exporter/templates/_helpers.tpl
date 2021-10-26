{{/* Generate the full name. */}}
{{- define "fullName" -}}
{{- required ".Values.redfish.name missing" .Values.redfish.name -}}
{{- end -}}
