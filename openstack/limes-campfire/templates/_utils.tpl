{{- define "campfire_image" -}}
  {{- if $.Values.campfire.image_tag -}}
    {{$.Values.global.registry}}/campfire:{{$.Values.campfire.image_tag}}
  {{- else -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- end -}}
{{- end -}}
