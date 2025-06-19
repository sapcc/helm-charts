{{- define "k8sevents.transform" }}
attributes/k8sevents:
  actions:
    - action: insert
      key: k8s.cluster.name
      value: ${cluster}
    - action: insert
      key: region
      value: ${region}
    - action: insert
      key: log.type
      value: "k8sevents"

{{- end }}

{{- define "k8sevents.pipeline" }}
logs/k8sevents:
  receivers: [k8s_events]
  processors: [attributes/k8sevents]
  exporters: [forward]
{{- end }}
