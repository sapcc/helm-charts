{{- /**********************************************************************************/ -}}
{{- define "swift_image" -}}
  {{- if ne .Values.image_version "DEFINED_BY_PIPELINE" -}}
    {{ .Values.global.registryAlternateRegion }}/{{ .Values.imageRegistry_repo }}:{{ .Values.image_version }}
  {{- else -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
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
