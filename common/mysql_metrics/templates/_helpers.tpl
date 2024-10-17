{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{- define "metrics_db_host" -}}
{{- if eq .Values.db_type "pxc" -}}
{{.Release.Name}}-percona-pxc.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.db_region}}.{{.Values.global.tld}}
{{- else if eq .Values.db_type "galera" -}}
{{.Release.Name}}-mariadb-galera.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
{{- else if eq .Values.db_type "pxc-db" -}}
{{.Release.Name}}-db-haproxy.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
{{- else -}}
{{.Release.Name}}-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end -}}
{{end}}

{{/*
Resolve secret and replace single quote with double single quote
This resolved secret could be put inside the single-quoted string inside yaml
*/}}
{{- define "mysql_metrics.resolve_secret_for_yaml" -}}
    {{- $str := . -}}
    {{- if (hasPrefix "vault+kvv2" $str ) -}}
        {{"{{"}} resolve "{{ $str }}" | replace "'" "''" {{"}}"}}
    {{- else -}}
        {{ $str | replace "'" "''" }}
{{- end -}}
{{- end -}}

{{/*
Construct the go-mysql driver DSN string
*/}}
{{- define "mysql_metrics.db_path_for_exporter" -}}
{{- $protocol := "mysql" -}}
{{- $username := include "mysql_metrics.resolve_secret_for_yaml" (required ".Values.db_user missing" .Values.db_user) -}}
{{- $password := "" -}}
{{- $address := include "metrics_db_host" . -}}
{{- $database := (required ".Values.db_name missing" .Values.db_name) -}}
{{- if hasKey .Values "db_password" -}}
    {{- $password = include "mysql_metrics.resolve_secret_for_yaml" .Values.db_password -}}
{{- else -}}
    {{- $password = include "mysql_metrics.resolve_secret_for_yaml" .Values.global.dbPassword -}}
{{- end -}}
{{ $protocol }}://{{ $username }}:{{ $password }}@tcp({{ $address }}:3306)/{{ $database }}
{{- end -}}

{{/* Needed for testing purposes only. */}}
{{define "RELEASE-NAME_db_host"}}testRelease-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "testRelease_db_host"}}testRelease-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
