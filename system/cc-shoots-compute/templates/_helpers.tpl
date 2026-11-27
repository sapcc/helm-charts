{{/*
Renders an ASNumber that handles both numeric and dotted string inputs.
YAML integers arrive as float64 in Helm and are formatted to avoid scientific notation.
Quoted dotted strings (e.g. "65161.5018") are passed through quoted.
Usage: {{ include "asNumber" .Values.networking.asNumber }}
*/}}
{{- define "asNumber" -}}
{{- if kindIs "float64" . -}}{{ printf "%.0f" . }}{{- else -}}{{ . | quote }}{{- end -}}
{{- end -}}

{{/* Share the shoot Secret only when non-overridden workers render identical ignition. */}}
{{- define "cc-shoots-compute.ignitionSecretName" -}}
{{- $ignition := include "cc-shoots-compute.kvmIgnition" (dict "root" .root "cluster" .cluster "worker" .worker) -}}
{{- $workerSpecific := not (empty .worker.extraIgnition) -}}
{{- range $other := .cluster.workers -}}
{{- if not $other.extraIgnition -}}
{{- $otherIgnition := include "cc-shoots-compute.kvmIgnition" (dict "root" $.root "cluster" $.cluster "worker" $other) -}}
{{- if ne $ignition $otherIgnition -}}
{{- $workerSpecific = true -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if $workerSpecific -}}
{{- printf "extraignition-compute-%s-%s" .shootName .workerName -}}
{{- else -}}
{{- printf "extraignition-compute-%s" .shootName -}}
{{- end -}}
{{- end -}}
