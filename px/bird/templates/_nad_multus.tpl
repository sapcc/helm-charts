{{- define "nad_multus" -}}
{{- $master := printf "vlan_%v" (required "multus_vlan is required for every domain" .domain_config.multus_vlan) }}
{{- if  .top.Values.hostNetworkDaemonSet.enabled }}
  {{- $master = printf "vlan%v" (required "multus_vlan is required for every domain" .domain_config.multus_vlan) }}
{{- end }}
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
        "master": "{{ $master }}",
        "mode": "bridge"
    }
{{ end }}
