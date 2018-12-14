{{- define "backup_configmap" -}}
{{- $volume := index . 1 -}}
{{- with index . 0 -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: cinder-backup-{{$volume.name}}
  labels:
  labels:
    system: openstack
    type: configuration
    component: cinder
data:
  cinder-backup.conf: |
{{ tuple . $volume | include "backup_conf" | indent 4 }}
{{- end -}}
{{- end -}}
