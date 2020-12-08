{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "prometheus-pushgateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "prometheus-pushgateway.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "prometheus-pushgateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create the name of the service account to use
*/}}
{{- define "prometheus-pushgateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "prometheus-pushgateway.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create default labels
*/}}
{{- define "prometheus-pushgateway.defaultLabels" -}}
{{- $labelChart := include "prometheus-pushgateway.chart" $ -}}
{{- $labelApp := include "prometheus-pushgateway.name" $ -}}
{{- $labels := dict "app" $labelApp "chart" $labelChart "release" .Release.Name "heritage" .Release.Service -}}
{{ merge .extraLabels $labels | toYaml | indent 4 }}
{{- end -}}

{{/*
Return the appropriate apiVersion for networkpolicy.
*/}}
{{- define "prometheus-pushgateway.networkPolicy.apiVersion" -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}


{{/*
define fqdn helper, from prometheus-server
*/}}
{{/* External URL of this Prometheus Pushgateway. */}}
{{- define "prometheus-pushgateway.externalURL" -}}
{{- if and .Values.ingress.hosts .Values.ingress.hostsFQDN -}}
{{- fail ".Values.ingress.hosts and .Values.ingress.hostsFQDN are mutually exclusive." -}}
{{- end -}}
{{- if .Values.ingress.hosts -}}
{{- $firstHost := first .Values.ingress.hosts -}}
{{- required ".Values.ingress.hosts must have at least one hostname set" $firstHost -}}.{{- required ".Values.global.region missing" .Values.global.region -}}.{{- required ".Values.global.domain missing" .Values.global.domain -}}
{{- else -}}
{{- $firstHost := first .Values.ingress.hostsFQDN -}}
{{- required ".Values.ingress.hostsFQDN must have at least one hostname set" $firstHost -}}
{{- end -}}
{{- end -}}

{{- define "fqdnHelper" -}}
{{- $host := index . 0 -}}
{{- $root := index . 1 -}}
{{- $host -}}.{{- required ".Values.global.region missing" $root.Values.global.region -}}.{{- required ".Values.global.domain missing" $root.Values.global.domain -}}
{{- end -}}
