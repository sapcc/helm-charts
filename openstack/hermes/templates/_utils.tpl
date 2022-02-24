{{- define "hermes_image" -}}
  {{- if contains "DEFINED" $.Values.hermes.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.hermes.image}}:{{$.Values.hermes.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "httpBasicAuth"}}
  {{- printf "%s:%s" .Values.global.elk_elasticsearch_http_user .Values.global.elk_elasticsearch_http_password | b64enc }}
{{- end }}

{{/* Generate the full name to match requirement in rabbitmq chart. Temp fix. */}}
{{- define "fullName" -}}
{{- required ".Values.hermes.name missing" .Values.hermes.name -}}
{{- end -}}
