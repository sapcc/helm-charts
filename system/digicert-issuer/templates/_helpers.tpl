{{- define "image" -}}
{{- required ".Values.image.repository missing" .Values.image.repository -}}:{{- required "image tag missing" (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end -}}
