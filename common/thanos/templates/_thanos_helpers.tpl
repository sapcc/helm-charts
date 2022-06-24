{{/* Generated objectStorageConfigName */}}
{{- define "thanos.objectStorageConfigName" -}}
prometheus-{{ include "thanos.fullName" . }}-storage-config
{{- end -}}

{{/* Thanos image. */}}
{{- define "thanosimage" -}}
{{- required ".Values.thanos.spec.baseImage missing" .Values.thanos.spec.baseImage -}}:{{- required ".Chart.appVersion missing" .Chart.AppVersion -}}
{{- end -}}

{{/* Thanos combined name */}}
{{- define "thanos.fullName" -}}
{{- required ".Values.name" .Values.name -}}-thanos
{{- end -}}
