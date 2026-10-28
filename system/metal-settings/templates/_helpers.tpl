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
Fail fast if CRDVersionControl.features.readinessGates.enabled=true but CRDVersionControl.apiVersions
still point at the plain metal-operator group ("metal.ironcore.dev/v1alpha1"), which has no
readinessGates/completionConditionType fields. The readiness-gate chain requires
metal-maintenance-operator's group-qualified apiVersions ("baseboard.metal.ironcore.dev/v1alpha1"
for BMCSettingsSet/BMCVersionSet, "system.metal.ironcore.dev/v1alpha1" for
BIOSSettingsSet/BIOSVersionSet).

Usage:
  {{- include "metal-settings.requireChainCapableAPI" . }}
*/}}
{{- define "metal-settings.requireChainCapableAPI" -}}
{{- $av := .Values.CRDVersionControl.apiVersions -}}
{{- if or (eq $av.bmcSettingsSet "metal.ironcore.dev/v1alpha1") (eq $av.bmcVersionSet "metal.ironcore.dev/v1alpha1") (eq $av.biosSettingsSet "metal.ironcore.dev/v1alpha1") (eq $av.biosVersionSet "metal.ironcore.dev/v1alpha1") -}}
{{- fail "metal-settings: CRDVersionControl.features.readinessGates.enabled=true requires CRDVersionControl.apiVersions.* to point at metal-maintenance-operator's groups (baseboard.metal.ironcore.dev/v1alpha1, system.metal.ironcore.dev/v1alpha1) — the metal-operator group (metal.ironcore.dev/v1alpha1) has no readinessGates/completionConditionType fields." -}}
{{- end -}}
{{- end -}}

{{/*
Fail fast if a machines.<vendor>.models.<name> entry still defines the legacy "bios:"/"bmc:"
keys, which were replaced by the "chain:" schema (see values.yaml for the chain schema).

Usage:
  {{- include "metal-settings.rejectLegacyBiosBmcKeys" (dict "vendor" $vendor "entryName" $entryName "entry" $entry) }}
*/}}
{{- define "metal-settings.rejectLegacyBiosBmcKeys" -}}
{{- if or .entry.bios .entry.bmc -}}
{{- fail (printf "metal-settings: machines.%s.models.%s still defines the legacy bios:/bmc: keys. These were replaced by chain: — see values.yaml for the chain schema." .vendor .entryName) -}}
{{- end -}}
{{- end -}}

{{/*
Render server selector matchExpressions from a serverFilters object.
Expected input:
  dict "serverFilters" (dict "included" (list ...) "excluded" (list ...)) "labelKey" $.Values.labelKeys.serverName

"labelKey" is optional and defaults to "kubernetes.metal.cloud.sap/name" if not provided.

Returns empty string if both lists are empty.
*/}}
{{- define "metal-settings.serverMatchExpressions" -}}
{{- $serverFilters := .serverFilters -}}
{{- $labelKey := .labelKey | default "kubernetes.metal.cloud.sap/name" -}}
{{- if or $serverFilters.included $serverFilters.excluded -}}
matchExpressions:
{{- if $serverFilters.included }}
  - key: {{ $labelKey }}
    operator: In
    values:
{{- range $serverFilters.included }}
      - {{ . | quote }}
{{- end }}
{{- end }}
{{- if $serverFilters.excluded }}
  - key: {{ $labelKey }}
    operator: NotIn
    values:
{{- range $serverFilters.excluded }}
      - {{ . | quote }}
{{- end }}
{{- end }}
{{- end -}}
{{- end -}}

