{{- define "ironic_configmap" -}}
{{- $hypervisor := index . 1 -}}
{{- with index . 0 -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: nova-compute-{{$hypervisor.name}}
  labels:
    system: openstack
    type: configuration
    component: nova
data:
  nova-compute.conf: |
{{ tuple . $hypervisor | include "nova_compute_ironic_conf" | indent 4 }}
{{- end -}}
{{- end -}}
