{{- define "share_netapp_configmap" -}}
{{- $context := index . 0 -}}
{{- $share := index . 1 -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $context.Release.Name }}-share-netapp-{{$share.name}}
  labels:
    system: openstack
    type: configuration
    component: manila
data:
  backend.conf: |
{{ list $context $share | include "share_netapp_conf" | indent 4 }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ $context.Release.Name }}-share-netapp-{{$share.name}}-secret
  labels:
    system: openstack
    type: configuration
    component: manila
data:
  backend-secret.conf: |
{{ list $context $share | include "share_netapp_conf_secret" | b64enc | indent 4 }}
---
{{- if eq $share.name "stnpca2-st051" }}
apiVersion: v1
kind: Secret
metadata:
  name: netapp-{{$share.name}}-manilauser
  labels:
    system: openstack
    type: configuration
    component: manila
stringData:
  username: {{ $share.username2 }}
  password: {{ $share.password2 }}
{{- end -}}
{{- end -}}
