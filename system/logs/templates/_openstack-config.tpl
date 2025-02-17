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
        - resource["k8s.container.name"] == "neutron-network-agent"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{WORD:loglevel} %{NOTSPACE:logger} \\[-\\] %{GREEDYDATA} method: %{WORD:uri_method} path: \"%{NOTSPACE:uri_path}\" status: %{NUMBER:uri_status} client-ip: %{IPV4:client_ip} project-id: %{NOTSPACE:project_id} os-network-id: %{NOTSPACE:os_network_id} os-router-id: %{NOTSPACE:os_router_id} os-instance-id: %{NOTSPACE:os_instance_id} req-duration: %{BASE10NUM:uri_req_duration:float} user-agent: \"%{NOTSPACE:user_agent}\"", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "(%{TIMESTAMP_ISO8601:logtime}|)( )?%{TIMESTAMP_ISO8601:timestamp}.%{NOTSPACE}? %{NUMBER:pid} %{WORD:loglevel} %{NOTSPACE:logger} \\[-\\] %{GREEDYDATA} method: %{WORD:uri_method} path: \"%{NOTSPACE:uri_path}\" status: %{NUMBER:uri_status} client-ip: %{IPV4:client_ip} project-id: %{NOTSPACE:project_id} os-network-id: %{NOTSPACE:os_network_id} os-router-id: %{NOTSPACE:os_router_id} os-instance-id: %{NOTSPACE:os_instance_id} req-duration: %{BASE10NUM:uri_req_duration:float} user-agent: \"%{NOTSPACE:user_agent}\"", true),"upsert")

transform/neutron-errors:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource["k8s.container.name"] == "neutron-server"
        - resource["k8s.container.name"] == "neutron-asr1k"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{TIMESTAMP_ISO8601:timestamp} %{NOTSPACE} %{NOTSPACE:loglevel} %{NOTSPACE:process} (\\[)?(req-)%{NOTSPACE:request_id} ?(g%{NOTSPACE:global_request_id}) ?%{NOTSPACE:user_id} ?%{NOTSPACE:project_id} ?%{NOTSPACE:domain_id} ?%{NOTSPACE:user_domain_id} ?%{NOTSPACE:project_domain_id}\\] %{IPV4:client_ip} \"%{WORD:request_method} %{NOTSPACE:request_path} HTTP/%{NOTSPACE}\" status: %{NUMBER:response}?( ).*len: %{NUMBER:content_length:integer} time: %{BASE10NUM:request_time:float} agent: %{NOTSPACE:agent}", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "Encoutered a requeable lock exception executing %{WORD:neutronTask:string} for model %{WORD:neutronModel:string} on device %{IP:neutronIp:string}", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "asr1k_exceptions.InconsistentModelException: %{WORD:neutronTask} for model %{WORD:neutronModel} cannot be executed on %{IP:neutronIp}", true),"upsert")
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

transform/openstack-manila:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource["k8s.container.name"] == "manila-api"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "(%{TIMESTAMP_ISO8601:logtime}|)( )?%{TIMESTAMP_ISO8601:access_timestamp}.%{NOTSPACE} %{NUMBER:pid} %{NOTSPACE:log_level} %{NOTSPACE:program} (\\[?)%{NOTSPACE:request_id} %{NOTSPACE:user_id} %{NOTSPACE:project_id} %{NOTSPACE:domain_id} %{NOTSPACE:id1} %{REQUESTID:id2}(\\]?) %{GREEDYDATA:log_request}", true, ["REQUESTID=[0-9A-Za-z-]+"]),"upsert")

transform/openstack-api:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["app.label.app_name"] == "cinder"
        - resource.attributes["app.label.app_name"] == "nova"
        - resource.attributes["app.label.app_name"] == "designate"
        - resource.attributes["app.label.app_name"] == "barbican"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{TIMESTAMP_ISO8601:timestamp} %{NOTSPACE} %{NOTSPACE:loglevel} %{NOTSPACE:process} (\\[)?(req-)%{NOTSPACE:request_id} ?(g%{NOTSPACE:global_request_id}) ?%{NOTSPACE:user_id} ?%{NOTSPACE:project_id} ?%{NOTSPACE:domain_id} ?%{NOTSPACE:user_domain_id} ?%{NOTSPACE:project_domain_id}\\] %{IPV4:client_ip} \"%{WORD:request_method} %{NOTSPACE:request_path} HTTP/%{NOTSPACE}\" status: %{NUMBER:response}?( ).*len: %{NUMBER:content_length:integer} time: %{BASE10NUM:request_time:float} agent: %{NOTSPACE:agent}", true),"upsert")

transform/non-openstack:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource["k8s.container.name"] == "sentry"
        - resource["k8s.container.name"] == "sentry"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{IP:remote_addr} %{NOTSPACE:ident} %{NOTSPACE:auth} \\[%{HAPROXYDATE:timestamp}\\] \"%{WORD:request_method} %{NOTSPACE:request_path} %{NOTSPACE:httpversion}\" %{NUMBER:response} %{NUMBER:content_length:integer} %{QUOTEDSTRING:url} \"%{GREEDYDATA:user_agent}\"?( )?(%{BASE10NUM:request_time:float})", true, ["HAPROXYDATE=%{MONTHDAY}/%{MONTH}/%{YEAR}:%{HAPROXYTIME}.%{INT}", "HAPROXYTIME=%{HOUR}:%{MINUTE}(?::%{SECOND})"]),"upsert")





transform/network-generic-ssh-exporter:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource["k8s.container.name"] == "network-generic-ssh-exporter"
      statements:
        - merge_maps(cache, ParseJSON(body), "upsert") where IsMatch(body, "^\\{")
        - set(attributes["log_level"], cache["level"])
        - set(attributes["msg"], cache["msg"])
        - merge_maps(attributes, ExtractGrokPatterns(msg, "{GREEDYDATA}: %{GREEDYDATA:ssh_reason} \^%{GREEDYDATA}on %{IPORHOST:ssh_ip}\:", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(msg, "Error parsing metric: %{GREEDYDATA:ssh_reason}\, address: %{IPORHOST:ssh_ip}", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(msg, "%{GREEDYDATA:ssh_reason}: dial tcp %{IPORHOST:ssh_ip}", true),"upsert")


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
