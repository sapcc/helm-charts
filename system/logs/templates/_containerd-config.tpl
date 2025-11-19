{{- define "containerd.transform" }}
transform/protocol:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["network.protocol.name"] != nil
      statements:
        - set(log.attributes["network.protocol.name"], ConvertCase(log.attributes["network.protocol.name"], "lower"))

transform/ingress:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["app.label.name"] == "ingress-nginx"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{IP:client.address} %{NOTSPACE:client.ident} %{NOTSPACE:client.auth} \\[%{HTTPDATE:httpdate}\\] \"%{WORD:request.method} %{NOTSPACE:request.path} %{WORD:network.protocol.name}/%{NOTSPACE:network.protocol.version}\" %{NUMBER:response} %{NUMBER:content_length:int} %{QUOTEDSTRING} \"%{GREEDYDATA:user_agent}\" %{NUMBER:request.length:int} %{BASE10NUM:request.time:float}( \\[%{NOTSPACE:service}\\])? ?(\\[\\])? %{IP:server.address}\\:%{NUMBER:server.port} %{NUMBER:upstream_response_length:int} %{BASE10NUM:upstream_response_time:float} %{NOTSPACE:upstream_status} %{NOTSPACE:request.id}", true),"upsert")
        - set(log.attributes["network.protocol.name"], ConvertCase(log.attributes["network.protocol.name"], "lower")) where log.attributes["network.protocol.name"] != nil
        - set(log.attributes["config.parsed"], "ingress-nginx") where log.attributes["client.address"] != nil

transform/perses:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "perses"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "time=%{QUOTEDSTRING} level=%{WORD:loglevel} msg=%{GREEDYDATA:msg}", true),"upsert")
        - set(log.attributes["config.parsed"], "perses")
{{ end }}

{{- define "containerd.receiver" }}
filelog/containerd:
  include_file_path: true
  include: [ /var/log/pods/*/*/*.log ]
  exclude: [ /var/log/pods/logs_logs-*/*/*.log, /var/log/pods/logs_fluent*/*/*.log ]
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
  processors: [k8sattributes,attributes/cluster,transform/ingress,transform/protocol,transform/perses]
  exporters: [forward]
{{- end }}
