{{/* Name of the Prometheus Alertmanager instance. */}}
{{- define "alertmanagerRelease.name" -}}
{{- $almValues := index .Values "prometheus-alertmanager" }}
{{- $almValues.name -}}
{{- end -}}

{{- define "slack.template" -}}
username: "Alertmanager"
text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
iconEmoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
title: "Alertmanager"
callbackId: "alertmanager"
color: {{"'{{template \"slack.sapcc.color\" . }}'"}}
sendResolved: true
{{- end -}}
