{{- define "openstack.receiver" }}
filelog/containerd:
  include_file_path: true
  include: [ /var/log/pods/*/*/*.log ]
  exclude: [ /var/log/pods/otel_logs-*, /var/log/pods/logs_*, /var/log/containers/fluent*, /var/log/containers/swift*, /var/log/pods/dns-recursor_unbound*, /var/log/pods/kube-system_wormhole* ]
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
{{- end }}

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
        - resource["k8s.container.name"] == "neutron-network-agent"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{WORD:loglevel} %{NOTSPACE:logger} \\[-\\] %{GREEDYDATA} %{NOTSPACE} %{WORD:uri_method} %{NOTSPACE} %{QUOTEDSTRING:uri_path} %{NOTSPACE} %{NUMBER:uri_status} %{NOTSPACE} %{IPV4:client_ip} %{NOTSPACE} %{NOTSPACE:project_id} %{NOTSPACE} %{NOTSPACE:os_network_id} %{NOTSPACE} %{NOTSPACE:os_router_id} %{NOTSPACE} %{NOTSPACE:os_instance_id} %{NOTSPACE} %{BASE10NUM:uri_req_duration} %{NOTSPACE} %{QUOTEDSTRING:user_agent}", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "(%{TIMESTAMP_ISO8601:logtime}|)( )?%{TIMESTAMP_ISO8601:timestamp}.%{NOTSPACE}? %{NUMBER:pid} %{WORD:loglevel} %{NOTSPACE:logger} \\[-\\] %{GREEDYDATA} %{NOTSPACE} %{WORD:uri_method} %{NOTSPACE} %{QUOTEDSTRING:uri_path} %{NOTSPACE} %{NUMBER:uri_status} %{NOTSPACE} %{IPV4:client_ip} %{NOTSPACE %{NOTSPACE:project_id} %{NOTSPACE} %{NOTSPACE:os_network_id} %{NOTSPACE} %{NOTSPACE:os_router_id} %{NOTSPACE} %{NOTSPACE:os_instance_id} %{NOTSPACE} %{BASE10NUM:uri_req_duration} %{NOTSPACE} %{QUOTEDSTRING:user_agent}", true),"upsert")

transform/neutron-errors:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource["k8s.container.name"] == "neutron-server"
        - resource["k8s.container.name"] == "neutron-asr1k"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{TIMESTAMP_ISO8601:timestamp} %{NOTSPACE} %{NOTSPACE:loglevel} %{NOTSPACE:process} (\\[)?(req-)%{NOTSPACE:request_id} ?(g%{NOTSPACE:global_request_id}) ?%{NOTSPACE:user_id} ?%{NOTSPACE:project_id} ?%{NOTSPACE:domain_id} ?%{NOTSPACE:user_domain_id} ?%{NOTSPACE:project_domain_id}\\] %{IPV4:client_ip} \"%{WORD:request_method} %{NOTSPACE:request_path} HTTP/%{NOTSPACE}\" %{NOTSPACE} %{NUMBER:response}?( ).*%{NOTSPACE} %{NUMBER:content_length} %{NOTSPACE} %{BASE10NUM:request_time} %{NOTSPACE} %{NOTSPACE:agent}", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "Encoutered a requeable lock exception executing %{WORD:neutronTask:string} for model %{WORD:neutronModel:string} on device %{IP:neutronIp:string}", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "asr1k_exceptions.InconsistentModelException?(:) %{WORD:neutronTask} for model %{WORD:neutronModel} cannot be executed on %{IP:neutronIp}", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{WORD:neutronTask} for model %{WORD:neutronModel} cannot be executed on %{IP:neutronIp} due to a model/device inconsistency.", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "Failed to bind port %{UUID:neutronPort:string} on host %{NOTSPACE:neutronHost:string} for vnic_type %{WORD:neutronVnicType:string} using segments", true),"upsert")

transform/openstack-ironic:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["app.label.name"] == "ironic-api"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{DATE_EU:timestamp}%{SPACE}%{GREEDYDATA}\"%{WORD:method}%{SPACE}%{IMAGE_METHOD:path}%{NOTSPACE}%{SPACE}%{NOTSPACE:httpversion}\"%{SPACE}%{NUMBER:response}", true, ["IMAGE_METHOD:\/v2\/images"]),"upsert")

{{- end }}

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
