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
{{- end }}
  initiatorname.iscsi: |
    InitiatorName=iqn.2008-11.org.linux-kvm
{{- end }}
