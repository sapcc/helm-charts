{{- define "image" -}}
{{- required ".Values.image.repository missing" .Values.image.repository -}}:{{- required ".Values.image.tag missing" .Values.image.tag -}}
{{- end -}}
