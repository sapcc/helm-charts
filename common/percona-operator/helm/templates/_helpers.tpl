{{/*
  Generate labels
  $ = global values
  version/noversion = enable/disable version fields in labels
  database = desired component name
  job = object type
  config = provided function
  include "percona-operator.labels" (list $ "version" "database" "sts" "database")
  include "percona-operator.labels" (list $ "version" "database" "job" "config")
*/}}
{{- define "percona-operator.labels" }}
{{- $ := index . 0 }}
{{- $component := index . 2 }}
{{- $type := index . 3 }}
{{- $function := index . 4 }}
app.kubernetes.io/name: {{ $.Chart.Name }}
app.kubernetes.io/instance: {{ $.Chart.Name }}-{{ $.Release.Name }}
app.kubernetes.io/component: {{ (index $.Values.image (printf "%s" $component)).softwarename }}-{{ $type }}-{{ $function }}
app.kubernetes.io/part-of: {{ $.Release.Name }}
  {{- if eq (index . 1) "version" }}
app.kubernetes.io/version: {{ (index $.Values.image (printf "%s" $component)).softwareversion }}-{{ (index $.Values.image (printf "%s" $component)).imageversion | int }}
helm.sh/chart: {{ $.Chart.Name }}-{{ $.Chart.Version | replace "+" "_" }}
  {{- end }}
{{- end }}