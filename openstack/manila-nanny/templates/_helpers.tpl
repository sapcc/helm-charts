{{/*
Expand the name of the chart.
*/}}
{{- define "manila-nanny.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "manila-nanny.fullname" -}}
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
{{- define "manila-nanny.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "manila-nanny.labels" -}}
helm.sh/chart: {{ include "manila-nanny.chart" . }}
{{ include "manila-nanny.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "manila-nanny.selectorLabels" -}}
app.kubernetes.io/name: {{ include "manila-nanny.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "manila-nanny.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "manila-nanny.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Check if any of the items are enabled
*/}}
{{- define "anyEnabled" -}}
  {{- $anyEnabled := false -}}
  {{- range $item, $enabled := .items -}}
    {{- if and (eq $enabled.enabled true) (not $anyEnabled) -}}
      {{- $anyEnabled = true -}}
    {{- end -}}
  {{- end -}}
  {{- $anyEnabled -}}
{{- end -}}

{{/*
Sentry environment variables
*/}}
{{- define "envSentry" -}}
{{- if .Values.sentry.enabled -}}
- name: SENTRY_DSN_SSL
  valueFrom:
    secretKeyRef:
      name: sentry
      key: manila.DSN
- name: SENTRY_DSN
  value: $(SENTRY_DSN_SSL)?verify_ssl=0
{{- end -}}
{{- end -}}

{{/* Namespace environment variable */}}
{{- define "envNamespace" -}}
name: NAMESPACE
valueFrom:
  fieldRef:
    fieldPath: metadata.namespace
{{- end -}}

{{/* Dependent service environment variable */}}
{{- define "envDependencyService" -}}
{{- if .Values.dependencyService -}}
name: DEPENDENCY_SERVICE
value: {{ .Values.dependencyService }}
{{- end -}}
{{- end -}}

{{/* Volume mounts */}}
{{- define "mountManilaConfig" -}}
- name: manila-etc
  mountPath: /etc/manila/manila.conf
  subPath: manila.conf
  readOnly: true
- name: manila-etc
  mountPath: /etc/manila/logging.ini
  subPath: logging.ini
  readOnly: true
- name: manila-etc-secrets
  mountPath: /etc/manila/secrets.conf
  subPath: secrets.conf
  readOnly: true
- name: manila-netapp-filers
  mountPath: /etc/manila/netapp-filers.yaml
  subPath: netapp-filers.yaml
  readOnly: true
{{- end -}}

{{/* Start shell command or sleep */}}
{{- define "shellCommand" -}}
{{ if not .Values.debug }}/bin/bash /scripts/{{ .script }}{{ else }}sleep inf{{ end }}
{{- end -}}

{{/* Configmap Hash (changes when netapp filer list is updated) */}}
{{- define "configmapHash" -}}
{{- if .Values.nannies.snapshot_missing.enabled -}}
configmap-filer-hash: {{ include (print .Template.BasePath "/configmap.yaml") . | sha256sum }}
{{- end -}}
{{- end -}}


{{- define "promPort" -}}
{{- if .prometheus_port -}}
ports:
  - name: metrics
    containerPort: {{ .prometheus_port }}
{{- end -}}
{{- end -}}

