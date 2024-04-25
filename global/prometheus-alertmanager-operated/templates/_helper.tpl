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

{{- define "email.template" -}}
html: {{`{{"'{{template \"cc_email_receiver.KubernikusKlusterLowOnObjectStoreQuota\" . }}'"}}`}}
{{- end -}}

{{- define "regions" -}}
ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
{{- end -}}

{{- define "regionsWithQA1" -}}
ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3|qa-de-1
{{- end -}}

{{- define "regionsWithGlobal" -}}
global|ap-ae-1|ap-au-1|ap-cn-1|ap-jp-1|ap-jp-2|ap-sa-1|ap-sa-2|eu-de-1|eu-de-2|eu-nl-1|la-br-1|na-ca-1|na-us-1|na-us-2|na-us-3
{{- end -}}

{{- define "clusterTypes" -}}
abapcloud|admin|controlplane|customer|internet|kubernikus|metal|scaleout|virtual
{{- end -}}

{{- define "supportGroups" -}}
compute|compute-storage-api|containers|email|identity|foundation|network-api|observability|src|network-data|network-security|network-lb|network-wan|storage
{{- end -}}

