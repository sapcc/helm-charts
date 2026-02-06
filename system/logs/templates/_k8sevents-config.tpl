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

transform/consolidate_label:
# consolidates the k8s labels coming from resource and attributes into a single label
  error_mode: ignore
  log_statements:
    - context: log
      statements:
        - set(resource.attributes["k8s.namespace.name"], attributes["k8s.namespace.name"])
        - set(resource.attributes["k8s.node.name"], attributes["k8s.node.name"])
        - delete_key(attributes, "k8s.namespace.name") 
        - delete_key(attributes, "k8s.node.name") 

{{- end }}

{{- define "k8sevents.pipeline" }}
logs/k8sevents:
  receivers: [k8s_events]
  processors: [attributes/k8sevents,transform/consolidate_label]
  exporters: [forward]
{{- end }}
