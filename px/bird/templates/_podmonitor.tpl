{{- define "podmonitor" -}}
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata: 
  labels:
    prometheus: infra-collector
  name: px
  namespace: px
spec: 
  namespaceSelector: 
    matchNames: 
    - px
  podMetricsEndpoints: 
  - honorLabels: true
    interval: 60s
    metricRelabelings: 
    - action: replace
      regex: ^bird_.+;{{ .Values.global.region }}-pxrs-([0-9])-s([0-9])-([0-9])
      replacement: $1
      sourceLabels: 
      - __name__
      - app
      targetLabel: pxdomain
    - action: replace
      regex: ^bird_.+;{{ .Values.global.region }}-pxrs-([0-9])-s([0-9])-([0-9])
      replacement: $2
      sourceLabels: 
      - __name__
      - app
      targetLabel: pxservice
    - action: replace
      regex: ^bird_.+;{{ .Values.global.region }}-pxrs-([0-9])-s([0-9])-([0-9])
      replacement: $3
      sourceLabels: 
      - __name__
      - app
      targetLabel: pxinstance
    - action: replace
      regex: ^bird_.+;BGP;(PL|TP|MN)-([A-Z0-9]*)-(.*)
      replacement: $1
      sourceLabels: 
      - __name__
      - proto
      - name
      targetLabel: peer_type
    - action: replace
      regex: ^bird_.+;BGP;(PL|TP|MN)-([A-Z0-9]*)-(.*)
      replacement: $2
      sourceLabels: 
      - __name__
      - proto
      - name
      targetLabel: peer_id
    - action: replace
      regex: ^bird_.+;BGP;(PL|TP|MN)-([A-Z0-9]*)-(.*)
      replacement: $3
      sourceLabels: 
      - __name__
      - proto
      - name
      targetLabel: peer_hostname
    path: /metrics
    port: metrics
    relabelings: 
    - action: labelmap
      regex: __meta_kubernetes_pod_label_(.+)
    - action: replace
      sourceLabels: 
      - __meta_kubernetes_namespace
      targetLabel: kubernetes_namespace
    - action: replace
      sourceLabels: 
      - __meta_kubernetes_pod_name
      targetLabel: kubernetes_pod_name
    - action: replace
      replacement: {{ .Values.global.region }}
      targetLabel: region
    - action: replace
      replacement: controlplane
      targetLabel: cluster_type
    - action: replace
      replacement: {{ .Values.global.region }}
      targetLabel: cluster
    scheme: http
    scrapeTimeout: 55s
  selector: 
    matchExpressions: 
    - key: app.kubernetes.io/name
      operator: In
      values: 
      - px
{{ end }}
