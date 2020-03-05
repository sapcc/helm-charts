{{/* Name of the Prometheus Alertmanager instance. */}}
{{- define "alertmanager.name" -}}
{{- required ".Values.name missing" .Values.name -}}
{{- end -}}

{{/* Fullname of the Prometheus Alertmanager instance. */}}
{{- define "alertmanager.fullname" -}}
alertmanager-{{- (include "alertmanager.name" .) -}}
{{- end -}}

{{/* External URL of this Prometheus Alertmanager instance. */}}
{{- define "alertmanager.externalURL" -}}
{{- if .Values.ingress.hostNameOverride -}}
{{- .Values.ingress.hostNameOverride -}}
{{- else -}}
{{- required ".Values.ingress.host missing" .Values.ingress.host -}}.{{- required ".Values.global.region missing" .Values.global.region -}}.{{- required ".Values.global.domain missing" .Values.global.domain -}}
{{- end -}}
{{- end -}}

{{/* Prometheus Alertmanager image. */}}
{{- define "alertmanager.image" -}}
{{- required ".Values.image.repository missing" .Values.image.repository -}}:{{- required ".Values.image.tag missing" .Values.image.tag -}}
{{- end -}}

{{/* Name of the PVC. */}}
{{- define "pvc.name" -}}
{{- default (include "alertmanager.fullname" .) .Values.persistence.name | quote -}}
{{- end -}}

{{- define "alerts.tier" -}}
{{- if and .Values.global .Values.global.tier }}
{{- .Values.global.tier -}}
{{- else -}}
{{- required ".Values.alerts.tier missing" .Values.alerts.tier -}}
{{- end -}}
{{- end -}}
