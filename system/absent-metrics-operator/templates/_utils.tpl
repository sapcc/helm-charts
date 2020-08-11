{{- define "absent_metrics_operator_image" -}}
  {{- if contains "DEFINED" $.Values.absent-metrics-operator.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.global.registry}}/absent-metrics-operator:{{$.Values.absent-metrics-operator.image_tag}}
  {{- end -}}
{{- end -}}
