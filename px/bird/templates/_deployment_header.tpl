{{- define "deployment_header" -}}
{{ $deployment_name := index . 0}}
{{ $apod := index . 1 }}
{{ $scheduling_labels := index . 2 }}
{{ $px_availability_zones := index . 3 }}
{{ $multus_vlan := index . 4 }}
{{ $service_number := index . 5 }}
{{ $service := index . 6 }}
{{ $domain_number := index . 7}}
{{ $domain := index . 8}}
{{ $instance_number := index . 9}}
{{ $instance := index . 10}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $deployment_name }}
  namespace: px
  labels:
    app: {{ $deployment_name }}
    pxservice: '{{ $service_number }}'
    pxdomain: '{{ $domain_number }}'
    pxinstance: '{{ $instance_number }}'
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ $deployment_name }}
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
        app: {{ $deployment_name }}
        pxservice: '{{ $service_number }}'
        pxdomain: '{{ $domain_number }}'
        pxinstance: '{{ $instance_number }}'
      annotations:
        k8s.v1.cni.cncf.io/networks: |
            [{ 'name': '{{ $deployment_name }}',
            'interface': 'vlan{{ required "multus_vlan is required for every domain"  $multus_vlan}}'}]
        prometheus.io/scrape: "true"
        prometheus.io/port: "9324"
        prometheus.io/targets: "infra-collector"
    spec:
{{- if $apod }}
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: failure-domain.beta.kubernetes.io/zone
                operator: In
                values:
                - {{ index $px_availability_zones (mod (sub $domain_number 1) (len  $px_availability_zones)) }}                
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: pxservice
                operator: In
                values:
                - {{ $service_number }}
            topologyKey: "kubernetes.cloud.sap/host"
{{- else }}
        tolerations:
            key: species
            operator: Equal
            value: px
            effect: NoSchedule
        nodeSelector:
            # This calculation only works if we have no more than 2 instances and no more than 2 scheduling labels per domain
            pxdomain: "{{ index (get $scheduling_labels $domain) (sub $instance_number 1) }}"
{{- end }}
{{- end }}