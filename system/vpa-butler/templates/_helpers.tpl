{{- define "image" -}}
{{- required ".Values.image.repository missing" .Values.image.repository -}}:{{- required ".Chart.AppVersion missing" .Chart.AppVersion -}}
{{- end -}}
