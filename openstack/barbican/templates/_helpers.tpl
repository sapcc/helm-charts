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

{{- define "barbican.db_service" }}
  {{- include "utils.db_host" . }}
{{- end }}

{{- define "barbican.service_dependencies" }}
  {{- template "barbican.db_service" . }}
{{- end }}

{{- define "barbican.tls.validate" -}}
{{- if .Values.tls.enabled }}
  {{- if not .Values.tls.keyGeneration }}
    {{- fail "tls.keyGeneration is required when tls.enabled (options: go-crypto, hsm-entropy, hsm-full, tpm-entropy)" }}
  {{- end }}
  {{- if not .Values.tls.keyWrapping }}
    {{- fail "tls.keyWrapping is required when tls.enabled (options: none, vault-transit, hsm, tpm)" }}
  {{- end }}
  {{- if not .Values.tls.keyStorage }}
    {{- fail "tls.keyStorage is required when tls.enabled (options: k8s-secret, vault-secret)" }}
  {{- end }}
  {{- if and (eq .Values.tls.keyWrapping "none") (eq .Values.tls.keyStorage "k8s-secret") (not .Values.tls.allowInsecureStorage) }}
    {{- fail "tls: unwrapped keys cannot be stored as plain-text K8s Secrets. Set tls.keyWrapping or tls.keyStorage, or set tls.allowInsecureStorage: true to acknowledge." }}
  {{- end }}
{{- end }}
{{- end }}
