{{- /* Parameters: (root context, instance name, hypervisor config). */ -}}
{{- $root := index . 0 }}
{{- $name := index . 1 }}
{{- $hv := index . 2 }}
{{- if eq $name "compute" }}
{{- fail "The hypervisor name 'compute' is reserved for the shared ConfigMap. Use a different name." }}
{{- end }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $root.Release.Name }}-{{ $name }}
  labels:
{{ tuple $root "nova" "compute" | include "helm-toolkit.snippets.kubernetes_metadata_labels" | indent 4 }}
data:
  040-hypervisor-{{ $name }}.conf: |
    {{- tuple $root $name $hv | include "nova.hypervisor.instance.conf" | nindent 4 -}}