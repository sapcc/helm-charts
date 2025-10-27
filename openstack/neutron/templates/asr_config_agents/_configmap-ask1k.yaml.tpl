{{- define "asr1k_configmap" -}}
{{- $context := index . 0 -}}
{{- $config_agent := index . 1 -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: neutron-etc-asr1k-{{$config_agent.name}}
  labels:
    system: openstack
    type: configuration
    component: neutron

data:
  asr1k.conf: |
{{ tuple $context $config_agent | include "asr1k_conf" | indent 4 }}
{{- end -}}
