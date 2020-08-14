{{- define "hermes_image" -}}
  {{- if contains "DEFINED" $.Values.hermes.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.hermes.image}}:{{$.Values.hermes.image_tag}}
  {{- end -}}
{{- end -}}
