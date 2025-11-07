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

{{/*
Return the FQDN name of the database instance.
*/}}
{{- define "mysql_metrics.db_host" -}}
    {{- $db_namespace := .Release.Namespace -}}
    {{- if hasKey .Values "db_namespace" -}}
        {{- $db_namespace = .Values.db_namespace -}}
    {{- end -}}
    {{- if .Values.db_instance_name_literal -}}
        {{ .Values.db_instance_name_literal }}.{{ $db_namespace }}.svc.kubernetes.{{ .Values.global.region }}.{{ .Values.global.tld }}
    {{- else -}}
        {{- if eq .Values.db_type "pxc" -}}
        {{ .Release.Name }}-percona-pxc.{{ $db_namespace }}.svc.kubernetes.{{ .Values.global.db_region }}.{{ .Values.global.tld }}
        {{- else if eq .Values.db_type "pxc-db" -}}
        {{ .Release.Name }}-db-haproxy.{{ $db_namespace }}.svc.kubernetes.{{ .Values.global.region }}.{{ .Values.global.tld }}
        {{- else -}}
        {{ .Release.Name }}-mariadb.{{ $db_namespace }}.svc.kubernetes.{{ .Values.global.region }}.{{ .Values.global.tld }}
        {{- end -}}
    {{- end -}}
{{- end }}

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
Construct the go-mysql driver DSN string.
*/}}
{{- define "mysql_metrics.db_path_for_exporter" -}}
    {{- $protocol := "mysql" -}}
    {{- $username := include "mysql_metrics.resolve_secret_for_yaml" (required ".Values.db_user missing" .Values.db_user) -}}
    {{- $password := "" -}}
    {{- $address := include "mysql_metrics.db_host" . -}}
    {{- if hasKey .Values "db_password" -}}
        {{- $password = include "mysql_metrics.resolve_secret_for_yaml" .Values.db_password -}}
    {{- else -}}
        {{- $password = include "mysql_metrics.resolve_secret_for_yaml" .Values.global.dbPassword -}}
    {{- end -}}
    {{- $database := (required ".Values.db_name missing" .Values.db_name) -}}
    {{ $protocol }}://{{ $username }}:{{ $password }}@tcp({{ $address }}:3306)/{{ $database }}
{{- end -}}

{{/*
Construct the go-mysql DSN string from connections map.
*/}}
{{- define "mysql_metrics.db_path_for_exporter_from_connections" -}}
    {{- $root := index . 0 -}}
    {{- $name := index . 1 -}}
    {{- $connection := index . 2 -}}
    {{- $protocol := "mysql" -}}
    {{- $username := include "mysql_metrics.resolve_secret_for_yaml" (required (printf "mysql_metrics.connections.%s.db_user missing" $name) $connection.db_user) -}}
    {{- $password := "" -}}
    {{- $address := include "mysql_metrics.db_host_from_connections" (tuple $root $connection) -}}
    {{- $password = include "mysql_metrics.resolve_secret_for_yaml" (required (printf "mysql_metrics.connections.%s.db_password missing" $name) $connection.db_password) -}}
    {{- $database := (required (printf "mysql_metrics.connections.%s.db_name missing" $name) $connection.db_name) -}}
    {{- $protocol }}://{{ $username }}:{{ $password }}@tcp({{ $address }}:3306)/{{ $database }}
{{- end -}}

{{/*
Return the service name of the database instance.
For pxc-global returns FQDN of the service in sepcified region.
*/}}
{{- define "mysql_metrics.db_host_from_connections" }}
    {{- $root := index . 0 -}}
    {{- $connection := index . 1 -}}
    {{- $prefix := $root.Release.Name -}}
    {{- $db_namespace := $root.Release.Namespace -}}
    {{- if hasKey $connection "db_namespace" -}}
        {{- $db_namespace = $connection.db_namespace -}}
    {{- end -}}
    {{- if $connection.db_instance_name_literal -}}
        {{ $connection.db_instance_name_literal }}.{{ $db_namespace }}.svc.kubernetes.{{ $root.Values.global.region }}.{{ $root.Values.global.tld }}
    {{- else -}}
        {{- if $connection.db_instance_name -}}
            {{- $prefix = printf "%s-%s" $root.Release.Name $connection.db_instance_name -}}
        {{- end -}}
        {{- if eq $connection.db_type "pxc" -}}
            {{ $prefix }}-percona-pxc.{{ $db_namespace }}.svc.kubernetes.{{ $root.Values.global.db_region }}.{{ $root.Values.global.tld }}
        {{- else if eq $connection.db_type "pxc-db" -}}
            {{ $prefix }}-db-haproxy.{{ $db_namespace }}.svc.kubernetes.{{ $root.Values.global.region }}.{{ $root.Values.global.tld }}
        {{- else -}}
            {{ $prefix }}-mariadb.{{ $db_namespace }}.svc.kubernetes.{{ $root.Values.global.region }}.{{ $root.Values.global.tld }}
        {{- end -}}
    {{- end -}}
{{- end }}

{{/* Needed for testing purposes only. */}}
{{define "RELEASE-NAME_db_host"}}testRelease-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "testRelease_db_host"}}testRelease-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
