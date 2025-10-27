{{- define "prometheusVMware.name" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- $vropshostname := split "." $name -}}
vmware-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- end -}}
