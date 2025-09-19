{{/*
Expand the name of the chart.
*/}}
{{- define "database-sync.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "database-sync.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "database-sync.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Charts owner-info labels
*/}}
{{- define "mariadb.ownerLabels" -}}
{{- if index .Values "owner-info" }}
ccloud/support-group: {{  index .Values "owner-info" "support-group" | quote }}
ccloud/service: {{  index .Values "owner-info" "service" | quote }}
{{- end }}
{{- end }}

{{/*
  Generate labels
  $ = global values
  version/noversion = enable/disable version fields in labels
  database-sync = desired component name
  job = object type
  config = provided function
  include "database-sync.labels" (list $ "version" "database-sync" "deployment" "database")
  include "database-sync.labels" (list $ "version" "database-sync" "job" "config")
*/}}
{{- define "database-sync.labels" }}
{{- $ := index . 0 }}
{{- $component := index . 2 }}
{{- $type := index . 3 }}
{{- $function := index . 4 }}
app.kubernetes.io/name: {{ $.Chart.Name }}
app.kubernetes.io/instance: {{ $.Release.Name }}-{{ $.Chart.Name }}
app.kubernetes.io/component: {{ include "database-sync.label.component" (list $component $type $function) }}
app.kubernetes.io/part-of: {{ $.Release.Name }}
  {{- if eq (index . 1) "version" }}
app.kubernetes.io/version: {{ $.Values.image.tag | default $.Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: "helm"
helm.sh/chart: {{ $.Chart.Name }}-{{ $.Chart.Version | replace "+" "_" }}
  {{- end }}
{{- end }}

{{/*
  Generate labels
  database-sync = desired component name
  job = object type
  config = provided function
  include "label.component" (list "database-sync" "deployment" "database")
  include "database-sync.label.component" (list "database-sync" "job" "config")
*/}}
{{- define "database-sync.label.component" }}
{{- $component := index . 0 }}
{{- $type := index . 1 }}
{{- $function := index . 2 }}
{{- $component }}-{{ $type }}-{{ $function }}
{{- end }}

{{/*
Default pod labels for linkerd
*/}}
{{- define "database-sync.linkerdPodAnnotations" }}
  {{- if and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested $.Values.linkerd.enabled }}
linkerd.io/inject: enabled
    {{- if $.Values.global.linkerd_use_native_sidecar }}
config.alpha.linkerd.io/proxy-enable-native-sidecar: "true"
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Create the config map content for sync pod
*/}}
{{- define "database-sync.configmap" -}}
{{- $v := .Values -}}
region: {{ $v.global.region | required "global.region is required" }}
loglevel: {{ $v.loglevel | default "info" | quote }}
{{- if $v.backup }}
backup:
  {{- if $v.backup.service }}
  service: {{ $v.backup.service | quote }}
  {{- end }}
  {{- if $v.backup.swift }}
  swift:
    container: {{ ($v.backup.swift.container | default (printf "mariadb-backup-%s" ($v.backup.region | default $v.global.region))) | quote }}
    creds:
      identityEndpoint: {{ $v.backup.swift.identityEndpoint | required "backup.swift.identityEndpoint is required" | quote }}
      user: {{ $v.backup.swift.user | default "db_backup" | quote }}
      userDomain: {{ $v.backup.swift.userDomain | default "Default" | quote }}
      project: {{ $v.backup.swift.project | default "master" | quote }}
      projectDomain: {{ $v.backup.swift.projectDomain | default "ccadmin" | quote }}
  {{- end }}
  {{- if $v.backup.s3 }}
  s3:
    sseCustomerAlgorithm: {{ $v.backup.s3.sseCustomerAlgorithm | default "AES256" | quote }}
    region: {{ required "missing AWS region" $v.global.mariadb.backup_v2.aws.region }}
    bucketName: {{ ($v.backup.s3.bucketName | default (printf "mariadb-backup-%s" ($v.backup.region | default ""))) | quote }}
  {{- end }}
{{- end }}
replication:
  sourceDB:
    host: {{ $v.source.host | default "" | quote }}
    port: {{ ($v.source.port | default 3306) | quote }}
    user: {{ $v.source.user | default "root" | quote }}
  targetDB:
    host: {{ $v.target.host | default "" | quote }}
    port: {{ ($v.target.port | default 3306) | quote }}
    user: {{ $v.target.user | default "root" | quote }}
  schemas:
  {{- if $v.databases }}
    {{- range $db := $v.databases }}
    - {{ $db | quote }}
    {{- end }}
  {{- end }}
  serverID: {{ $v.serverID | default 991 }}
  binlogMaxReconnectAttempts: {{ $v.binlogMaxReconnectAttempts | default 10 }}
{{- end }}
