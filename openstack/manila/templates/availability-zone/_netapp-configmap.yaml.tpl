{{- define "share_netapp_configmap" -}}
{{- $context := index . 0 -}}
{{- $share := index . 1 -}}
{{- $az := index . 2 -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: share-netapp-{{$share.name}}
  labels:
    system: openstack
    type: configuration
    component: manila
data:
  backend.conf: |
{{ list $context $share $az| include "share_netapp_conf" | indent 4 }}
{{- end -}}
