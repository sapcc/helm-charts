When passed via `helm upgrade --set`, the image tag is misinterpreted as a float64. So special care is needed to render it correctly.

{{- define "hermes_image" -}}
  {{- if typeIs "string" $.Values.hermes.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{- if typeIs "float64" .Values.hermes.image_tag -}}
      {{$.Values.hermes.image}}:{{$.Values.hermes.image_tag | printf "%0.f"}}
    {{- else -}}
      {{$.Values.hermes.image}}:{{$.Values.hermes.image_tag}}
    {{- end -}}
  {{- end -}}
{{- end -}}
