{{/* Name of the Prometheus Alertmanager instance. */}}
{{- define "alertmanagerRelease.name" -}}
{{- $almValues := index .Values "prometheus-alertmanager" }}
{{- $almValues.name -}}
{{- end -}}

{{- define "slack.template" -}}
username: "Alertmanager"
title: {{"'{{template \"slack.sapcc.title\" . }}'"}}
titleLink: {{"'{{template \"slack.sapcc.titlelink\" . }}'"}}
text: {{"'{{template \"slack.sapcc.text\" . }}'"}}
pretext: {{"'{{template \"slack.sapcc.pretext\" . }}'"}}
iconEmoji: {{"'{{template \"slack.sapcc.iconemoji\" . }}'"}}
callbackId: "alertmanager"
color: {{"'{{template \"slack.sapcc.color\" . }}'"}}
sendResolved: true
{{- end -}}
