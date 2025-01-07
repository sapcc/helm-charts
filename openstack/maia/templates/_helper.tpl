{{- define "prometheusVMware.fullName" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- $vropshostname := split "." $name -}}
prometheus-vmware-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- end -}}

{{- define "prometheusVMwareFederationMatches" -}}
vrops_virtualmachine_(?:
{{- range .Values.prometheus_vmware.matches -}}
{{- . | trimPrefix "vrops_virtualmachine_" -}}|
{{- end -}}
){{- if .Values.prometheus_vmware.neo.enabled }}|vrops_hostsystem_(?:
{{- range .Values.prometheus_vmware.neo.matches -}}
{{- . | trimPrefix "vrops_hostsystem_" -}}|
{{- end -}}
)
{{- end -}}
{{- end -}}

{{- define "prometheusCephFederationMatches" -}}
objectstore_(?:
{{- range .Values.prometheus_ceph.matches -}}
{{- . | trimPrefix "objectstore_" -}}|
{{- end -}}
)
{{- end -}}