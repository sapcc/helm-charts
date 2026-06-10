{{/*
Expand the name of the chart.
*/}}
{{- define "metal-settings.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "metal-settings.fullname" -}}
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
{{- define "metal-settings.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "metal-settings.labels" -}}
helm.sh/chart: {{ include "metal-settings.chart" . }}
{{ include "metal-settings.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "metal-settings.selectorLabels" -}}
app.kubernetes.io/name: {{ include "metal-settings.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "metal-settings.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "metal-settings.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generic filter check: determines if an item should be included based on included/excluded lists
Returns: "true" if item should be included, "" (empty string) otherwise

Usage:
  {{- if include "metal-settings.shouldInclude" (dict "item" $vendor "filters" $.Values.biosSettings.filters.vendors) }}

Filter Logic:
  - If filters.included is empty/nil: include all items (unless explicitly excluded)
  - If filters.included has values: only include items in that list
  - If filters.excluded has values: exclude those items (takes precedence over included)
  - If item appears in both included and excluded: excluded wins
*/}}
{{- define "metal-settings.shouldInclude" -}}
{{- $included := or (not .filters.included) (has .item .filters.included) -}}
{{- $excluded := and .filters.excluded (has .item .filters.excluded) -}}
{{- if and $included (not $excluded) -}}
true
{{- end -}}
{{- end -}}

{{/*
Render server selector matchExpressions from a serverFilters object.
Expected input:
  dict "serverFilters" (dict "included" (list ...) "excluded" (list ...))

Returns empty string if both lists are empty.
*/}}
{{- define "metal-settings.serverMatchExpressions" -}}
{{- $serverFilters := .serverFilters -}}
{{- if or $serverFilters.included $serverFilters.excluded -}}
matchExpressions:
{{- if $serverFilters.included }}
  - key: kubernetes.metal.cloud.sap/name
    operator: In
    values:
{{- range $serverFilters.included }}
      - {{ . | quote }}
{{- end }}
{{- end }}
{{- if $serverFilters.excluded }}
  - key: kubernetes.metal.cloud.sap/name
    operator: NotIn
    values:
{{- range $serverFilters.excluded }}
      - {{ . | quote }}
{{- end }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Region filter helpers per CRD purpose.

Behavior:
  - If .Values.global.region is empty/unset: include all entries (backward compatible)
  - If .Values.global.region is set: evaluate params.regionFilter

Supported per-purpose fields:
  - bios.settingsParams.regionFilter
  - bios.versionParams.regionFilter
  - bmc.settingsParams.regionFilter
  - bmc.versionParams.regionFilter

regionFilter semantics (same as other filters):
  - included: [] => include all regions
  - included: [qa-de-1] => include only listed regions
  - excluded: [qa-de-1] => exclude listed regions (takes precedence)
  - wildcard "*" is supported in included/excluded
*/}}
{{- define "metal-settings.regionFilterMatch" -}}
{{- $region := .region -}}
{{- $filter := .filter | default dict -}}
{{- $includedList := (get $filter "included") | default (list) -}}
{{- $excludedList := (get $filter "excluded") | default (list) -}}
{{- $included := or (eq (len $includedList) 0) (has $region $includedList) (has "*" $includedList) -}}
{{- $excluded := or (has $region $excludedList) (has "*" $excludedList) -}}
{{- if and $included (not $excluded) -}}
true
{{- end -}}
{{- end -}}

{{/*
Generic purpose-based region matcher.
Expected input:
  dict "root" $ "entry" $entry "section" "bios|bmc" "paramsKey" "settingsParams|versionParams"
*/}}
{{- define "metal-settings.purposeRegionMatch" -}}
{{- $globalValues := (get .root.Values "global") | default dict -}}
{{- $deployRegion := (get $globalValues "region") | default "" -}}
{{- if not $deployRegion -}}
true
{{- else -}}
{{- $section := (get .entry .section) | default dict -}}
{{- $params := (get $section .paramsKey) | default dict -}}
{{- $regionFilter := (get $params "regionFilter") | default (dict "included" (list) "excluded" (list)) -}}
{{- include "metal-settings.regionFilterMatch" (dict "region" $deployRegion "filter" $regionFilter) -}}
{{- end -}}
{{- end -}}

{{- define "metal-settings.biosSettingsRegionMatch" -}}
{{- include "metal-settings.purposeRegionMatch" (dict "root" .root "entry" .entry "section" "bios" "paramsKey" "settingsParams") -}}
{{- end -}}

{{- define "metal-settings.biosVersionRegionMatch" -}}
{{- include "metal-settings.purposeRegionMatch" (dict "root" .root "entry" .entry "section" "bios" "paramsKey" "versionParams") -}}
{{- end -}}

{{- define "metal-settings.bmcSettingsRegionMatch" -}}
{{- include "metal-settings.purposeRegionMatch" (dict "root" .root "entry" .entry "section" "bmc" "paramsKey" "settingsParams") -}}
{{- end -}}

{{- define "metal-settings.bmcVersionRegionMatch" -}}
{{- include "metal-settings.purposeRegionMatch" (dict "root" .root "entry" .entry "section" "bmc" "paramsKey" "versionParams") -}}
{{- end -}}

{{/*
Require global.region for every render.
This chart relies on region-aware filtering and should not render without it.
*/}}
{{- define "metal-settings.requireGlobalRegion" -}}
{{- $globalValues := (get .Values "global") | default dict -}}
{{- $deployRegion := (get $globalValues "region") | default "" -}}
{{- if not $deployRegion -}}
{{- fail "global.region must be set (e.g. --set global.region=qa-de-1)" -}}
{{- end -}}
{{- end -}}

