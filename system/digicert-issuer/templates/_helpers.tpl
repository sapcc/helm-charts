{{- define "image" -}}
{{- required ".Values.image.repository missing" .Values.image.repository -}}:v{{- required ".Chart.AppVersion missing" .Chart.AppVersion -}}
{{- end -}}
