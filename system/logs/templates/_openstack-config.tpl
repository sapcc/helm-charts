{{- define "openstack.receiver" }}
filelog/containerd:
  include_file_path: true
  include: [ /var/log/pods/*/*/*.log ]
  exclude: [ /var/log/pods/otel_logs-*, /var/log/pods/logs_*, /var/log/containers/swift* ]
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

filelog/containerd-swift:
  include_file_path: true
  include: [ /var/log/containers/swift* ]
  operators:
    - id: container-parser-swift
      type: container
    - id: parser-containerd-swift
      type: add
      field: resource["container.runtime"]
      value: "containerd"
    - id: container-label
      type: add
      field: attributes["log.type"]
      value: "containerd"
{{end}}


{{- define "openstack.transform" }}
transform/ingress:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["app.label.name"] == "ingress-nginx"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{IP:client.address} %{NOTSPACE:client.ident} %{NOTSPACE:client.auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:request_method} %{NOTSPACE:request_path} %{WORD:network.protocol.name}/%{NOTSPACE:network.protocol.version}\" %{NUMBER:response} %{NUMBER:content_length:int} %{QUOTEDSTRING} \"%{GREEDYDATA:user_agent}\" %{NUMBER:request_length:int} %{BASE10NUM:request_time:float}( \\[%{NOTSPACE:service}\\])? ?(\\[\\])? %{IP:server.address}\\:%{NUMBER:server.port} %{NUMBER:upstream_response_length:int} %{BASE10NUM:upstream_response_time:float} %{NOTSPACE:upstream_status} %{NOTSPACE:request_id}", true),"upsert")
        - set(attributes["network.protocol.name"], ConvertCase(attributes["network.protocol.name"], "lower")) where attributes["network.protocol.name"] != nil
        - set(attributes["config.parsed"], "ingress-nginx") where attributes["client.address"] != nil

transform/neutron-agent:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "neutron-network-agent"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{WORD:loglevel} %{NOTSPACE:logger} \\[-\\] %{GREEDYDATA} method: %{WORD:uri_method} path: \"%{NOTSPACE:uri_path}\" status: %{NUMBER:uri_status} client-ip: %{IPV4:client_ip} project-id: %{NOTSPACE:project_id} os-network-id: %{NOTSPACE:os_network_id} os-router-id: %{NOTSPACE:os_router_id} os-instance-id: %{NOTSPACE:os_instance_id} req-duration: %{BASE10NUM:uri_req_duration:float} user-agent: \"%{NOTSPACE:user_agent}\"", true),"upsert")


transform/network-generic-ssh-exporter:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource["k8s.container.name"] == "network-generic-ssh-exporter"
      statements:
        - - merge_maps(cache, ParseJSON(body), "upsert") where IsMatch(body, "^\\{")
        - set(attributes["log_level"], cache["level"])
        - set(attributes["msg"], cache["msg"])





{{ end }}

{{- define "openstack.pipeline" }}
logs/containerd:
  receivers: [filelog/containerd]
  processors: [k8sattributes,attributes/cluster,transform/ingress,transform/protocol]
  exporters: [forward]

logs/containerd-swift:
  receivers: [filelog/containerd-swift]
  processors: [k8sattributes,attributes/cluster,transform/ingress,transform/protocol]
  exporters: [forward]
{{- end }}
