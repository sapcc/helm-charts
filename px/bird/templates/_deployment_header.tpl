{{- define "deployment_header" -}}
{{- $apods := .top.Values.apods }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "bird.instance.deployment_name" . }}
  namespace: px
  labels: {{ include "bird.instance.labels" . | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels: {{ include "bird.instance.labels" . | nindent 8 }}
  strategy:
    type: Recreate
  template:
    metadata:
      labels: {{ include "bird.instance.labels" . | nindent 8 }}
        {{ include "bird.alert.labels" . | nindent 8 }}
        app.kubernetes.io/name: px
      annotations:
        k8s.v1.cni.cncf.io/networks: '[{ "name": "{{ include "bird.instance.deployment_name" . }}", "interface": "vlan{{ .domain_config.multus_vlan }}"}]'
    spec:
      affinity: {{ include "bird.domain.affinity" . | nindent 8 }}
      tolerations: {{ include "bird.domain.tolerations" . | nindent 8 }}
{{- end }}
