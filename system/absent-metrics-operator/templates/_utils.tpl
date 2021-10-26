{{- define "absent_metrics_operator_image" -}}
  {{- if empty $.Values.global.dockerHubMirror -}}
    sapcc/absent-metrics-operator:{{$.Values.imageTag}}
  {{- else -}}
    {{$.Values.global.dockerHubMirror}}/sapcc/absent-metrics-operator:{{$.Values.imageTag}}
  {{- end -}}
{{- end -}}
