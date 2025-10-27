{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
- action: replace
  target_label: region
  replacement: {{ required ".Values.global.region missing" $root.Values.global.region }}

- action: replace
  target_label: cluster_type
  replacement: {{ required ".Values.global.clusterType missing" $root.Values.global.clusterType }}

- action: replace
  target_label: cluster
  replacement: {{ if $root.Values.global.cluster }}{{ $root.Values.global.cluster }}{{ else }}{{ $root.Values.global.region }}{{ end }}

- action: replace
  source_labels: [alertname]
  target_label: incident_group_key
  replacement: {{ printf "%s_%s_$1" $root.Values.global.region ($root.Values.global.cluster | default $root.Values.global.region) }}
