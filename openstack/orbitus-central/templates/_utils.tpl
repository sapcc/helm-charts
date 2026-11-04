{{- define "orbitus_image" -}}
  {{- if not $.Values.orbitus.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registry }}/orbitus:{{ $.Values.orbitus.image_tag }}
  {{- end -}}
{{- end -}}
