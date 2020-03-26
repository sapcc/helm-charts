When passed via `helm upgrade --set`, the image tag is misinterpreted as a float64. So special care is needed to render it correctly.

{{- define "limes_image" -}}
  {{- if typeIs "string" $.Values.limes.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{- if typeIs "float64" .Values.limes.image_tag -}}
      {{$.Values.global.registry}}/limes:{{$.Values.limes.image_tag | printf "%0.f"}}
    {{- else -}}
      {{$.Values.global.registry}}/limes:{{$.Values.limes.image_tag}}
    {{- end -}}
  {{- end -}}
{{- end -}}
