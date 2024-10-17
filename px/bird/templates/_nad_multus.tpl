{{- define "nad_multus" -}}
{{- $vlan:= .domain_config.multus_vlan -}}
{{- $ip:= .instance_config.bird_ip -}}
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: {{ include "bird.statefulset.deployment_name" . }}
  namespace: px
spec:
  config: |
    {
        "cniVersion": "0.3.0",
        "type": "macvlan",
        "master": "vlan_{{ required "multus_vlan is required for every domai" $vlan }}",
        "mode": "bridge",
        "ipam": {
        "type": "static",
        "addresses": [{ "address": "{{ required "bird_ip must be set" $ip }}"}]
        }
    }
{{ end }}
