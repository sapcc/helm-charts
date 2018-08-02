When passed via `helm upgrade --set`, the image tag is misinterpreted as a float64. So special care is needed to render it correctly.

{{- define "keppel_image" -}}
  {{- if typeIs "string" $.Values.keppel.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{- if typeIs "float64" .Values.keppel.image_tag -}}
      {{$.Values.keppel.image}}:{{$.Values.keppel.image_tag | printf "%0.f"}}
    {{- else -}}
      {{$.Values.keppel.image}}:{{$.Values.keppel.image_tag}}
    {{- end -}}
  {{- end -}}
{{- end -}}
