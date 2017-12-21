{{/*
Expand the name of the chart.
*/}}
{{- define "swift-common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 24 | replace "_" "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 24 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "swift-common.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 24 | replace "_" "-" -}}
{{- end -}}

{{- /**********************************************************************************/ -}}
When passed via `helm upgrade --set`, the image_version is misinterpreted as a float64. So special care is needed to render it correctly.
{{- define "swift-common.image" -}}
  {{- if typeIs "string" (index .Values "swift-common" "image_version") -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{- if typeIs "float64" (index .Values "swift-common" "image_version") -}}
      {{.Values.global.imageRegistry}}/monsoon/swift-{{ index .Values "swift-common" "release" }}:{{ index .Values "swift-common" "image_version" | printf "%0.f"}}
    {{- else -}}
      {{.Values.global.imageRegistry}}/monsoon/swift-{{ index .Values "swift-common" "release" }}:{{ index .Values "swift-common" "image_version" }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- /**********************************************************************************/ -}}
{{- define "swift-common.bin_cm_name" }}
{{- $name := printf "%s-%s" .Release.Name "swift-common" | trunc 24 | replace "_" "-" -}}
{{- printf "%s-%s" $name "bin" -}}
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift-common.daemonset_annotations" }}
scheduler.alpha.kubernetes.io/tolerations: '[{"key":"species","value":{{ index .Values "swift-common" "species" | quote }}}]'
{{- end -}}

{{- /**********************************************************************************/ -}}
{{- define "swift-common.daemonset_tolerations" }}
{{- if ge .Capabilities.KubeVersion.Minor "7" }}
tolerations:
- key: "species"
  operator: "Equal"
  value: {{ index .Values "swift-common" "species" | quote}}
  effect: "NoSchedule"
{{- end }}
{{- end -}}
