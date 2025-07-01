{{- define "k8sevents.transform" }}
attributes/k8sevents:
  actions:
    - action: insert
      key: k8s.node.name
      value: ${KUBE_NODE_NAME}
    - action: insert
      key: k8s.namespace.name
      from_attribute: k8s.namespace.name
    - action: insert
      key: k8s.cluster.name
      value: ${cluster}
    - action: insert
      key: region
      value: ${region}
    - action: insert
      key: log.type
      value: "k8sevents"

resource/consolidate_label:
  attributes:
    - key: k8s.namespace.name
      from_attribute: k8s.namespace.name
      action: upsert

{{- end }}

{{- define "k8sevents.pipeline" }}
logs/k8sevents:
  receivers: [k8s_events]
  processors: [attributes/k8sevents,resource/consolidate_label]
  exporters: [forward]
{{- end }}
