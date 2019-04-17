{{/* Name of the Prometheus. */}}
{{- define "prometheus.name" -}}
{{- required ".Values.name missing" .Values.name -}}
{{- end -}}

{{/* Fullname of the Prometheus. */}}
{{- define "prometheus.fullName" -}}
prometheus-{{- (include "prometheus.name" .) -}}
{{- end -}}

{{/* External URL of this Prometheus. */}}
{{- define "prometheus.externalURL" -}}
{{- required ".Values.ingress.host missing" .Values.ingress.host -}}.{{- required ".Values.global.region missing" .Values.global.region -}}.{{- required ".Values.global.domain missing" .Values.global.domain -}}
{{- end -}}

{{/* Prometheus image. */}}
{{- define "prometheus.image" -}}
{{- required ".Values.image.repository missing" .Values.image.repository -}}:{{- required ".Values.image.tag missing" .Values.image.tag -}}
{{- end -}}

{{/* Name of the PVC. */}}
{{- define "pvc.name" -}}
{{- default .Values.name .Values.persistence.name | quote -}}
{{- end -}}

{{/* The name of the serviceAccount. */}}
{{- define "serviceAccount.name" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "prometheus.fullName" . ) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/* Alertmanager configuration. */}}
{{- define "alertmanager.config" -}}
- scheme: https
  timeout: 10s
  static_configs:
  - targets:
{{ toYaml .Values.alertmanagers | indent 6 }}
{{- end -}}
