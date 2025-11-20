{{- define "nad_multus" -}}
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: "vlan{{ .domain_config.multus_vlan }}"
  labels: {{ include "bird.domain.labels" . | nindent 4 }}
spec:
  config: |
    {
        "cniVersion": "0.3.0",
        "type": "macvlan",
        "master": "vlan_{{ required "multus_vlan is required for every domain" .domain_config.multus_vlan }}",
        "mode": "bridge"
    }
{{ end }}
