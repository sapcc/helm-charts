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

{{- define "prometheusVMware.name" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- $vropshostname := split "." $name -}}
vmware-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- end -}}

{{- define "prometheusVMware.fullName" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- $vropshostname := split "." $name -}}
prometheus-vmware-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- end -}}

{{- define "maiaFederationMatches" -}}
vrops_virtualmachine_(?:
{{- range .Values.maiaFederation.matches -}}
{{- . | trimPrefix "vrops_virtualmachine_" -}}|
{{- end -}}
){{- if .Values.maiaFederation.neo.enabled }}|vrops_hostsystem_(?:
{{- range .Values.maiaFederation.neo.matches -}}
{{- . | trimPrefix "vrops_hostsystem_" -}}|
{{- end -}}
)
{{- end -}}
{{- end -}}
