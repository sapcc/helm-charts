{{/* Generate the full name. */}}
{{- define "fullName" -}}
{{- required ".Values.redfish.name missing" .Values.redfish.name -}}
{{- end -}}
{{- define "registry" -}}
{{- if .Values.global.registry -}}
{{- .Values.global.registry -}}
{{- else -}}
keppel.eu-de-1.cloud.sap/ccloud
{{- end -}}
{{- end -}}
