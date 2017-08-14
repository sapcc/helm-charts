When passed via `helm upgrade --set`, the image tag is misinterpreted as a float64. So special care is needed to render it correctly.

{{- define "image_version" -}}
  {{- if typeIs "string" $.Values.image_version -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{- if typeIs "float64" .Values.image_version -}}
      {{$.Values.image_version | printf "%0.f"}}
    {{- else -}}
      {{$.Values.image_version}}
    {{- end -}}
  {{- end -}}
{{- end -}}
