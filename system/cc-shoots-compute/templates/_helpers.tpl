{{/*
Renders an ASNumber that handles both numeric and dotted string inputs.
YAML integers arrive as float64 in Helm and are formatted to avoid scientific notation.
Quoted dotted strings (e.g. "65161.5018") are passed through quoted.
Usage: {{ include "asNumber" .Values.networking.asNumber }}
*/}}
{{- define "asNumber" -}}
{{- if kindIs "float64" . -}}{{ printf "%.0f" . }}{{- else -}}{{ . | quote }}{{- end -}}
{{- end -}}
