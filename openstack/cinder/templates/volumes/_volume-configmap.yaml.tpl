{{- define "volume_configmap" }}
{{- $name := index . 1 }}
{{- $volume := index . 2 }}
{{- with index . 0 -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-volume-{{ $name }}
  labels:
    system: openstack
    type: configuration
    component: cinder
data:
  nfs_shares: |
    {{- range $_, $value := $volume.nfs_shares }}
    {{ $value.host }}:{{ $value.path }}
    {{- end }}
  cinder-volume.conf: |
{{ tuple . $name $volume | include "volume_conf" | indent 4 }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-volume-{{ $name }}-secret
  labels:
    system: openstack
    type: configuration
    component: cinder
type: Opaque
data: 
  cinder-volume-secrets.conf: |
{{ tuple . $name $volume | include "volume_conf_secrets" | b64enc | indent 4 }}
{{- end }}
{{- end }}
