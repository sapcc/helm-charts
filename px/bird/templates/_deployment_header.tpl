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
{{- if len .top.Values.apods  | eq 0 }}
{{- fail "You must supply at least one apod for scheduling" -}}
{{ end }}
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.cloud.sap/apod
                operator: In
                values: 
{{- range $site := keys .top.Values.apods | sortAlpha }}
{{- range get $.top.Values.apods  $site | sortAlpha }}
                - {{ . }}
{{- end }}
{{- end }}
{{- if .top.Values.prevent_hosts }}
              - key: kubernetes.cloud.sap/host
                operator: NotIn
                values:
{{ .top.Values.prevent_hosts | toYaml | indent  16 }}
{{- end }}
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: "kubernetes.cloud.sap/host"
            labelSelector:
              matchExpressions:
              - key: pxservice
                operator: In
                values:
                - {{ .service_number | quote }}
{{- if and (ge (len .top.Values.global.availability_zones ) 2) $.top.Values.az_redundancy }}
{{- if lt (len (keys .top.Values.apods))  2 }}
{{- fail "If the region consists of multiple AZs, PX must be scheduled in at least 2" -}}
{{- end }}
          - topologyKey: topology.kubernetes.io/zone
            labelSelector:
              matchExpressions:
              - key: pxservice
                operator: In
                values:
                - {{ .service_number | quote }}
              - key: pxdomain
                operator: In
                values:
                - {{ .domain_number | quote }}
{{- end }}
{{- if .top.Values.tolerate_arista_fabric }}
      tolerations:
      - key: "fabric"
        operator: "Equal"
        value: "arista"
        effect: "NoSchedule"
{{- end }}
{{- end }}
