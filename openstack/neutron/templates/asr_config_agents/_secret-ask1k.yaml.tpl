{{- define "asr1k_secret" -}}
{{- $context := index . 0 -}}
{{- $config_agent := index . 1 -}}
apiVersion: v1
kind: Secret
metadata:
  name: neutron-etc-asr1k-secrets-{{ $config_agent.name }}
  labels:
    system: openstack
    type: configuration
    component: neutron
type: Opaque
data:
  asr1k_secrets.conf: |
{{ tuple $context $config_agent | include "asr1k_sec" | b64enc | indent 4 }}
{{- end -}}
