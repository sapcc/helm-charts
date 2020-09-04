{{- define "limes_image" -}}
  {{- if contains "DEFINED" $.Values.limes.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.global.registry}}/limes:{{$.Values.limes.image_tag}}
  {{- end -}}
{{- end -}}
