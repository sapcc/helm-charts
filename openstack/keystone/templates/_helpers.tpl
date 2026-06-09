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

{{- define "keystone.memcached_host" -}}
{{- if .Values.global.is_global_region -}}
{{.Release.Name}}-memcached.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.db_region}}.{{.Values.global.tld}}
{{- else -}}
{{.Release.Name}}-memcached.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
{{- end -}}
{{- end -}}

{{- define "keystone.service_dependencies" }}
  {{- template "keystone.db_service" . }},{{ template "keystone.memcached_service" . }}
{{- end }}

{{- define "keystone.db_service" }}
  {{- if or .Values.percona_cluster.enabled (eq .Values.dbType "pxc-global") }}
    {{- .Release.Name }}-percona-pxc
  {{- else }}
    {{- include "utils.db_host" . }}
  {{- end }}
{{- end }}

{{- define "keystone.memcached_service" }}
{{- .Release.Name }}-memcached
{{- end }}

{{- define "2faproxy.selectorLabels" -}}
app.kubernetes.io/name: 2faproxy
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "2faproxy.labels" -}}
helm.sh/chart: {{ include "name" . }}
{{ include "2faproxy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "job_name" }}
  {{- $name := index . 1 }}
  {{- with index . 0 }}
    {{- $bin := include "utils.proxysql.proxysql_signal_stop_script" . | trim }}
    {{- $all := list $bin (include "utils.proxysql.job_pod_settings" . ) (include "utils.proxysql.volume_mount" . ) (include "utils.proxysql.container" . ) (include "utils.proxysql.volumes" .) | join "\n" }}
    {{- $hash := empty .Values.proxysql.mode | ternary $bin $all | sha256sum }}
{{- .Release.Name }}-{{ $name }}-{{ substr 0 4 $hash }}-{{ .Values.api.imageTag | required "Please set api.imageTag or similar"}}
  {{- end }}
{{- end }}

{{- define "keystone.job_dependencies" }}
  {{- if .Release.IsInstall }}
    {{- printf "%s,%s" (tuple . "job-migration" | include "job_name") (tuple . "job-bootstrap" | include "job_name") }}
  {{- else if .Values.run_db_migration }}
    {{- tuple . "job-migration" | include "job_name" }}
  {{- end }}
{{- end }}

{{/*
kubernetes-entrypoint init container using the sapcc fork from ghcrIoMirrorAlternateRegion.
Usage: tuple . (dict "SERVICE" "svc1,svc2" "JOBS" "job1") | include "keystone.kubernetes_entrypoint_init_container" | indent N
Empty values are skipped so callers may pass "" for optional dependencies.
*/}}
{{- define "keystone.kubernetes_entrypoint_init_container" }}
  {{- $envAll := index . 0 }}
  {{- $params := index . 1 }}
- name: kubernetes-entrypoint
  image: {{ $envAll.Values.global.ghcrIoMirrorAlternateRegion | required ".Values.global.ghcrIoMirrorAlternateRegion unset " }}/sapcc/kubernetes-entrypoint:{{ $envAll.Values.imageVersionKubernetesEntrypoint | required ".Values.imageVersionKubernetesEntrypoint is unset" }}
  command:
  - kubernetes-entrypoint
  env:
  - name: COMMAND
    value: "true"
  - name: POD_NAME
    valueFrom: {fieldRef: {fieldPath: metadata.name}}
  - name: NAMESPACE
    valueFrom: {fieldRef: {fieldPath: metadata.namespace}}
  {{- range $k, $v := $params }}
  {{- if $v }}
  - name: DEPENDENCY_{{ $k | upper }}
    value: {{ $v }}
  {{- end }}
  {{- end }}
{{- end }}

{{- define "prodel_url" }}
    {{- if not (empty .Values.prodel.url) -}}
        {{- .Values.prodel.url -}}
    {{- else -}}
        {{- $ns := "prodel" -}}

        {{- if .Values.global.is_global_region -}}
        {{- $ns = .Values.prodel.prodelNamespace | default "prodel" -}}
        {{- end -}}

        {{- printf "http://prodel.%s.svc/check-delete_project/%%(project_id)s" $ns -}}
    {{- end }}
{{- end }}
