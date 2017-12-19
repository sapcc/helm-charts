{{- /**********************************************************************************/ -}}
When passed via `helm upgrade --set`, the image_version is misinterpreted as a float64. So special care is needed to render it correctly.
{{- define "swift_image" -}}
  {{- if typeIs "string" .Values.image_version -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{- if typeIs "float64" .Values.image_version -}}
      {{.Values.global.imageRegistry}}/monsoon/swift-{{.Values.release}}:{{.Values.image_version | printf "%0.f"}}
    {{- else -}}
      {{.Values.global.imageRegistry}}/monsoon/swift-{{.Values.release}}:{{.Values.image_version}}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- /**********************************************************************************/ -}}

Create a default fully qualified app name.
We truncate at 24 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
{{- define "fullname" -}}
  {{- $release := index . 0 -}}
  {{- $chart := index . 1 -}}
  {{- $values := index . 2 -}}
  {{- $name := default $chart.Name $values.nameOverride -}}
  {{- printf "%s-%s" $release.Name $name | trunc 24 -}}
{{- end -}}

