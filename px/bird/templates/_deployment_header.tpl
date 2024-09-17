{{- define "deployment_header" -}}
{{- $apods := .top.Values.apods }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "bird.instance.deployment_name" . }}
  namespace: px
  labels:
    app: {{ include "bird.instance.deployment_name" .  | quote }}
    pxservice: '{{ .service_number }}'
    pxdomain: '{{ .domain_number }}'
    pxinstance: '{{ .instance_number }}'
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ include "bird.instance.deployment_name" . | quote }}
      pxservice: '{{ .service_number }}'
      pxdomain: '{{ .domain_number }}'
      pxinstance: '{{ .instance_number }}'
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        alert-tier: px
        alert-service: px
        app: {{ include "bird.instance.deployment_name" .  | quote }}
        pxservice: '{{ .service_number }}'
        pxdomain: '{{ .domain_number }}'
        pxinstance: '{{ .instance_number }}'
        app.kubernetes.io/name: px
      annotations:
        k8s.v1.cni.cncf.io/networks: '[{ "name": "{{ include "bird.instance.deployment_name" . }}", "interface": "vlan{{ .domain_config.multus_vlan }}"}]'
    spec:
      affinity: {{ include "bird.domain.affinity" . | nindent 8 }}
{{- if .top.Values.tolerate_arista_fabric }}
      tolerations:
      - key: "fabric"
        operator: "Equal"
        value: "arista"
        effect: "NoSchedule"
{{- end }}
{{- end }}
