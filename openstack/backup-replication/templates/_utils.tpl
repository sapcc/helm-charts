{{- define "swift_http_import_image" -}}
  {{- if contains "DEFINED" $.Values.swift_http_import.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.global.registry}}/swift-http-import:{{$.Values.swift_http_import.image_tag}}
  {{- end -}}
{{- end -}}
