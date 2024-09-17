{{- define "nad_multus" -}}
{{- $deployment_name := index . 0 | required "deployment_name cannot be empty" }}
{{- $vlan:= index . 1 -}}
{{- $ip:= index . 2 -}}
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: {{ $deployment_name }}
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
