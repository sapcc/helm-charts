{{- define "k8sobjects.transform" }}
attributes/k8sobjects:
  actions:
    - action: insert
      key: k8s.node.name
      value: ${KUBE_NODE_NAME}
    - key: k8s.namespace.name
      from_attribute: k8s.namespace.name
      action: insert
    - action: insert
      key: k8s.cluster.name
      value: ${cluster}
    - action: insert
      key: region
      value: ${region}
    - action: insert
      key: log.type
      value: "k8sobjects"

{{- end }}

{{- define "k8sobjects.pipeline" }}
logs/k8sobjects:
  receivers: [k8sobjects]
  processors: [attributes/k8sobjects]
  exporters: [forward]
{{- end }}

