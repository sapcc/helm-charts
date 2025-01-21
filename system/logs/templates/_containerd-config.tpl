{{- define "containerd.transform" }}
transform/protocol:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["network.protocol.name"] != nil
      statements:
        - set(attributes["network.protocol.name"], ConvertCase(attributes["network.protocol.name"], "lower"))
{{ end }}

{{- define "containerd.receiver" }}
filelog/containerd:
  include_file_path: true
  include: [ /var/log/pods/*/*/*.log ]
  exclude: [ /var/log/pods/otel_logs-*, /var/log/pods/logs_* ]
  operators:
    - id: container-parser
      type: container
    - id: parser-containerd
      type: add
      field: resource["container.runtime"]
      value: "containerd"
    - id: container-label
      type: add
      field: attributes["log.type"]
      value: "containerd"
{{end}}

{{- define "containerd.pipeline" }}
logs/containerd:
  receivers: [filelog/containerd]
  processors: [k8sattributes,attributes/cluster,transform/ingress,transform/protocol]
  exporters: [forward]
{{- end }}