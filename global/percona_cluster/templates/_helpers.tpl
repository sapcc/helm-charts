{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "percona-xtradb-cluster.name" -}}
{{- default "pxc" .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}

{{- define "fullName" -}}
{{- $name := default "percona-pxc" .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a short cluster name in order to fulfill Percona's `wsrep_cluster_name` variable max size.
https://www.percona.com/doc/percona-xtradb-cluster/LATEST/wsrep-system-index.html#wsrep_cluster_name
*/}}
{{- define "percona-cluster.shortname" -}}
{{- $name := default "pxc" .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 32 | trimSuffix "-" -}}
{{- end -}}

{{/* Helper to turn list into a comma-separated string */}}
{{- define "helm-toolkit.utils.joinListWithComma" -}}
{{- $local := dict "first" true -}}
{{- range $k, $v := . -}}{{- if not $local.first -}},{{- end -}}{{- $v -}}{{- $_ := set $local "first" false -}}{{- end -}}
{{- end -}}

{{/* Generate the service label for the templated Prometheus alerts. */}}
{{- define "alerts.service" -}}
{{- if .Values.alerts.service -}}
{{- .Values.alerts.service -}}
{{- else -}}
{{- .Release.Name -}}
{{- end -}}
{{- end -}}
