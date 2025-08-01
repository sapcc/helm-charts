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
{{- $name := default $.Chart.Name $.Values.nameOverride -}}
{{- printf "%s-%s" $.Release.Name $name | trunc 63 | replace "_" "-" | trimSuffix "-" -}}
{{- end -}}

{{- define "rabbitmq._validate_users" -}}
    {{- $envAll := . }}
    {{- $users := $envAll.users }}
    {{- $addDefaultUser := $envAll.addDefaultUser }}
    {{- range $key, $user := $users }}
      {{- if or (ne $key "default") $addDefaultUser }}
        {{- if not $user.user }}
            {{- fail (printf "%v.user missing" $key) }}
        {{- else if hasPrefix "-" $user.user }}
            {{- fail (printf "%v.user starts with hypen" $key) }}
        {{- else if not $user.password }}
            {{- fail (printf "%v.password missing" $key) }}
        {{- else if hasPrefix "-" $user.password }}
            {{- fail (printf "%v.password starts with hypen" $key) }}
        {{- end }}
      {{- end }}
    {{- end }}
{{- end }}

{{/* Generate the service label for the templated Prometheus alerts. */}}
{{- define "alerts.service" -}}
{{- if .Values.alerts.service -}}
{{- .Values.alerts.service -}}
{{- else -}}
{{- .Release.Name -}}
{{- end -}}
{{- end -}}

{{- define "dockerHubMirror" -}}
{{- if .Values.use_alternate_registry -}}
{{- .Values.global.dockerHubMirrorAlternateRegion -}}
{{- else -}}
{{- .Values.global.dockerHubMirror -}}
{{- end -}}
{{- end -}}

{{- define "dockerRegistry" -}}
{{- if .Values.use_alternate_registry -}}
{{- .Values.global.registryAlternateRegion -}}
{{- else -}}
{{- .Values.global.registry -}}
{{- end -}}
{{- end -}}

{{- define "rabbitmq_maintenance_affinity" }}
          - weight: 1
            preference:
              matchExpressions:
              - key: cloud.sap/maintenance-state
                operator: In
                values:
                - operational
{{- end }}

{{- define "rabbitmq_node_reinstall_affinity" }}
          - weight: 1
            preference:
              matchExpressions:
              - key: cloud.sap/deployment-state
                operator: NotIn
                values:
                - reinstalling
{{- end }}

{{/*
  Generate labels
  $ = global values
  version/noversion = enable/disable version fields in labels
  rabbitmq = desired component name
  job = object type
  config = provided function
  include "rabbitmq.labels" (list $ "version" "rabbitmq" "deployment" "messagequeue")
  include "rabbitmq.labels" (list $ "version" "rabbitmq" "job" "config")
*/}}
{{- define "rabbitmq.labels" }}
{{- $ := index . 0 }}
{{- $component := index . 2 }}
{{- $type := index . 3 }}
{{- $function := index . 4 }}
app: {{ template "fullname" $ }}
app.kubernetes.io/name: {{ $.Chart.Name }}
app.kubernetes.io/instance: {{ template "fullname" $ }}
app.kubernetes.io/component: {{ include "label.component" (list $component $type $function) }}
app.kubernetes.io/part-of: {{ $.Release.Name }}
  {{- if eq (index . 1) "version" }}
app.kubernetes.io/version: {{ $.Values.imageTag | regexFind "[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}" }}
app.kubernetes.io/managed-by: "helm"
helm.sh/chart: {{ $.Chart.Name }}-{{ $.Chart.Version | replace "+" "_" }}
  {{- end }}
{{- end }}

{{/*
  Generate labels
  rabbitmq = desired component name
  job = object type
  config = provided function
  include "label.component" (list "rabbitmq" "deployment" "messagequeue")
  include "label.component" (list "rabbitmq" "job" "config")
*/}}
{{- define "label.component" }}
{{- $component := index . 0 }}
{{- $type := index . 1 }}
{{- $function := index . 2 }}
{{- $component }}-{{ $type }}-{{ $function }}
{{- end }}
