{{- define "deployment_header" -}}
{{- $deployment_name := index . 0 | required "deployment_name cannot be empty"}}
{{- $azs := index . 1}}
{{- $scheduling_labels := index . 2 }}
{{- $apods := index . 3 }}
{{- $multus_vlan := index . 4 | required "multus_vlan is required for every domain" }}
{{- $service_number := index . 5 }}
{{- $service := index . 6 }}
{{- $domain_number := index . 7}}
{{- $domain := index . 8}}
{{- $instance_number := index . 9}}
{{- $instance := index . 10}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $deployment_name }}
  namespace: px
  labels:
    app: {{ $deployment_name | quote }}
    pxservice: '{{ $service_number }}'
    pxdomain: '{{ $domain_number }}'
    pxinstance: '{{ $instance_number }}'
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ $deployment_name | quote }}
      pxservice: '{{ $service_number }}'
      pxdomain: '{{ $domain_number }}'
      pxinstance: '{{ $instance_number }}'
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  template:
    metadata:
      labels:
        alert-tier: px
        alert-service: px
        app: {{ $deployment_name }}
        pxservice: '{{ $service_number }}'
        pxdomain: '{{ $domain_number }}'
        pxinstance: '{{ $instance_number }}'
      annotations:
        k8s.v1.cni.cncf.io/networks: '[{ "name": "{{ $deployment_name }}", "interface": "vlan{{ $multus_vlan}}"}]'
        prometheus.io/scrape: "true"
        prometheus.io/port: "9324"
        prometheus.io/targets: "infra-collector"
    spec:
{{- if len $apods | ne 0 }}
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.cloud.sap/apod
                operator: In
                values: 
{{- range $az_apods := values $apods }}
{{- range $az_apods }}
                - {{ . }}
{{- end }}
{{- end }}
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: "kubernetes.cloud.sap/host"
            labelSelector:
              matchExpressions:
              - key: pxservice
                operator: In
                values:
                - {{ $service_number | quote }}
{{- if ge (len $azs) 2 }}
{{- if lt (len (keys $apods))  2  }}
{{- fail "If the region consists of multiple AZs, PX must be scheduled in at least 2" -}}
{{- end }}
          - topologyKey: failure-domain.beta.kubernetes.io/zone
            labelSelector:
              matchExpressions:
              - key: pxservice
                operator: In
                values:
                - {{ $service_number | quote }}
              - key: pxdomain
                operator: In
                values:
                - {{ $domain_number | quote }}
{{- end }}
{{- else }}
{{ $domain_scheduling_labels := get $scheduling_labels $domain }}
{{- if $domain_scheduling_labels | len | eq 0 -}}
{{- fail "scheduling_labels must be set if not running on apod" -}}
{{- end }}
      tolerations:
        - key: species
          operator: Equal
          value: px
          effect: NoSchedule
      nodeSelector:
          # This calculation only works if we have no more than 2 instances and no more than 2 scheduling labels per domain
          pxdomain: "{{ index $domain_scheduling_labels (mod (sub $instance_number 1) (len $domain_scheduling_labels)) }}"
{{- end }}
{{- end }}
