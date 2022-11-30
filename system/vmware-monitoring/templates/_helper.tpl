{{- define "vropsExporter.name" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- $vropshostname := split "." $name -}}
{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- end -}}

{{- define "vropsExporter.fullName" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- $vropshostname := split "." $name -}}
vrops-exporter-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- end -}}

{{- define "vropsInventoryExporter.fullName" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- $vropshostname := split "." $name -}}
vrops-inventory-exporter-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- end -}}

{{- define "prometheusVMware.fullName" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- $vropshostname := split "." $name -}}
prometheus-vmware-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- end -}}
