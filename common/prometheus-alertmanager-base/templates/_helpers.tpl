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
{{- required ".Values.image.repository missing" .Values.image.repository -}}:{{- required ".Chart.AppVersion missing" .Chart.AppVersion -}}
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

{{- define "fqdnHelper" -}}
{{- $host := index . 0 -}}
{{- $root := index . 1 -}}
{{- $host -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.domain missing" $root.Values.global.domain -}}
{{- end -}}

{{- define "alerts.support_group" -}}
{{- if .Values.global.support_group | default false }}
{{- .Values.global.support_group -}}
{{- else -}}
{{- required "Either .Values.alerts.support_group or .Values.global.support_group must be set" .Values.alerts.support_group -}}
{{- end -}}
{{- end -}}
