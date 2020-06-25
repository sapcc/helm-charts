{{- define "image_version" -}}
  {{- if contains "DEFINED" .image_version -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{.image_version}}
  {{- end -}}
{{- end -}}
