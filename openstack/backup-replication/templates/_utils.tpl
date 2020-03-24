When passed via `helm upgrade --set`, the image tag is misinterpreted as a float64. So special care is needed to render it correctly.

{{- define "swift_http_import_image" -}}
  {{- if typeIs "string" $.Values.swift_http_import.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{- if typeIs "float64" .Values.swift_http_import.image_tag -}}
      {{$.Values.global.registry}}/swift-http-import:{{$.Values.swift_http_import.image_tag | printf "%0.f"}}
    {{- else -}}
      {{$.Values.global.registry}}/swift-http-import:{{$.Values.swift_http_import.image_tag}}
    {{- end -}}
  {{- end -}}
{{- end -}}
