{{- define "absent_metrics_operator_image" -}}
  {{- $tag := index $.Values "absent-metrics-operator" "image_tag" -}}
  {{- if contains "DEFINED" $tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.global.registry}}/absent-metrics-operator:{{$tag}}
  {{- end -}}
{{- end -}}
