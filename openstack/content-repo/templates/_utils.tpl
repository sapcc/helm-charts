When passed via `helm upgrade --set`, the image version is misinterpreted as a float64. So special care is needed to render it correctly.

{{- define "image_version" -}}
  {{- if typeIs "string" .image_version -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{- if typeIs "float64" .image_version -}}
      {{.image_version | printf "%0.f"}}
    {{- else -}}
      {{.image_version}}
    {{- end -}}
  {{- end -}}
{{- end -}}
