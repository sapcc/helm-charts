{{- define "openstack.receiver" }}
filelog/containerd:
  include_file_path: true
  include: [ /var/log/pods/*/*/*.log ]
  exclude: [ /var/log/pods/logs_logs-*/*/*.log, /var/log/pods/logs_fluent*/*/*.log, /var/log/pods/swift*/*/*.log, /var/log/pods/dns-recursor_unbound*/*/*.log, /var/log/pods/kube-system_wormhole*/*/*.log ]
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

filelog/containerd_swift:
  include_file_path: true
  include: [ /var/log/pods/swift*/*/*.log ]
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
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{IP:client.address} %{NOTSPACE:client.ident} %{NOTSPACE:client.auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:request_method} %{NOTSPACE:request_path} %{WORD:network.protocol.name}/%{NOTSPACE:network.protocol.version}\" %{NUMBER:response} %{NUMBER:content_length} %{QUOTEDSTRING} \"%{GREEDYDATA:user_agent}\" %{NUMBER:request_length} %{BASE10NUM:request_time:float}( \\[%{NOTSPACE:service}\\])? ?(\\[\\])? %{IP:server.address}\\:%{NUMBER:server.port} %{NUMBER:upstream_response_length} %{BASE10NUM:upstream_response_time:float} %{NOTSPACE:upstream_status} %{NOTSPACE:request_id}", true),"upsert")
        - set(attributes["network.protocol.name"], ConvertCase(attributes["network.protocol.name"], "lower")) where attributes["network.protocol.name"] != nil
        - set(attributes["config.parsed"], "ingress-nginx") where attributes["client.address"] != nil

transform/neutron_agent:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "neutron-network-agent"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{WORD:loglevel} %{NOTSPACE:logger} \\[-\\] %{GREEDYDATA} %{NOTSPACE} %{WORD:request_method} %{NOTSPACE} %{QUOTEDSTRING:request_path} %{NOTSPACE} %{NUMBER:request_status} %{NOTSPACE} %{IPV4:client.address} %{NOTSPACE} %{NOTSPACE:project_id} %{NOTSPACE} %{NOTSPACE:os_network_id} %{NOTSPACE} %{NOTSPACE:os_router_id} %{NOTSPACE} %{NOTSPACE:os_instance_id} %{NOTSPACE} %{BASE10NUM:request_duration} %{NOTSPACE} %{QUOTEDSTRING:user_agent}", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "(%{TIMESTAMP_ISO8601:logtime}|)( )?%{TIMESTAMP_ISO8601:timestamp}.%{NOTSPACE}? %{NUMBER:pid} %{WORD:loglevel} %{NOTSPACE:logger} \\[-\\] %{GREEDYDATA} %{NOTSPACE} %{WORD:request_method} %{NOTSPACE} %{QUOTEDSTRING:request_path} %{NOTSPACE} %{NUMBER:request_status} %{NOTSPACE} %{IPV4:client.address} %{NOTSPACE %{NOTSPACE:project_id} %{NOTSPACE} %{NOTSPACE:os_network_id} %{NOTSPACE} %{NOTSPACE:os_router_id} %{NOTSPACE} %{NOTSPACE:os_instance_id} %{NOTSPACE} %{BASE10NUM:request_duration} %{NOTSPACE} %{QUOTEDSTRING:user_agent}", true),"upsert")

transform/neutron_errors:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "neutron-server"
        - resource.attributes["k8s.container.name"] == "neutron-asr1k"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{TIMESTAMP_ISO8601:timestamp} %{NOTSPACE} %{NOTSPACE:loglevel} %{NOTSPACE:process} (\\[)?(req-)%{NOTSPACE:request_id} ?(g%{NOTSPACE:global_request_id}) ?%{NOTSPACE:user_id} ?%{NOTSPACE:project_id} ?%{NOTSPACE:domain_id} ?%{NOTSPACE:user_domain_id} ?%{NOTSPACE:project_domain_id}\\] %{IPV4:client.address} \"%{WORD:request_method} %{NOTSPACE:request_path} HTTP/%{NOTSPACE}\" %{NOTSPACE} %{NUMBER:response}?( ).*%{NOTSPACE} %{NUMBER:content_length} %{NOTSPACE} %{BASE10NUM:request_time} %{NOTSPACE} %{NOTSPACE:agent}", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{TIMESTAMP_ISO8601:timestamp} %{NOTSPACE} %{NOTSPACE:loglevel} %{NOTSPACE:process} (\\[)?(req-)%{NOTSPACE:request_id} ?(g%{NOTSPACE:global_request_id}) ?%{NOTSPACE:user_id} ?%{NOTSPACE:project_id} ?%{NOTSPACE:domain_id} ?%{NOTSPACE:user_domain_id} ?%{NOTSPACE:project_domain_id}\\]", true), "upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "Encoutered a requeable lock exception executing %{WORD:neutronTask:string} for model %{WORD:neutronModel:string} on device %{IP:neutronIp:string}", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "asr1k_exceptions.InconsistentModelException?(:) %{WORD:neutronTask} for model %{WORD:neutronModel} cannot be executed on %{IP:neutronIp}", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{WORD:neutronTask} for model %{WORD:neutronModel} cannot be executed on %{IP:neutronIp} due to a model/device inconsistency.", true),"upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "Failed to bind port %{UUID:neutronPort:string} on host %{NOTSPACE:neutronHost:string} for vnic_type %{WORD:neutronVnicType:string} using segments", true),"upsert")

transform/openstack_ironic:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.deployment.name"] == "ironic-api"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{DATE_EU:timestamp}%{SPACE}%{GREEDYDATA}\"%{WORD:method}%{SPACE}%{IMAGE_METHOD:path}%{NOTSPACE}%{SPACE}%{NOTSPACE:httpversion}\"%{SPACE}%{NUMBER:response}", true, ["IMAGE_METHOD=/v2/images"]),"upsert")

transform/openstack_manila:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "manila-api"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "(%{TIMESTAMP_ISO8601:logtime}|)( )?%{TIMESTAMP_ISO8601:access_timestamp}.%{NOTSPACE} %{NUMBER:pid} %{NOTSPACE:loglevel} %{NOTSPACE:program} (\\[?)%{NOTSPACE:request_id} %{NOTSPACE:user_id} %{NOTSPACE:project_id} %{NOTSPACE:domain_id} %{NOTSPACE:id1} %{REQUESTID:id2}(\\]?) %{GREEDYDATA:log_request}", true, ["REQUESTID=[0-9A-Za-z-]+"]),"upsert")

transform/openstack_api:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.deployment.name"] == "cinder-api"
        - resource.attributes["k8s.deployment.name"] == "nova-api"
        - resource.attributes["k8s.deployment.name"] == "designate-api"
        - resource.attributes["k8s.deployment.name"] == "barbican-api"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{TIMESTAMP_ISO8601:timestamp} %{NOTSPACE} %{NOTSPACE:loglevel} %{NOTSPACE:process} (\\[)?(req-)%{NOTSPACE:request_id} ?(g%{NOTSPACE:global_request_id}) ?%{NOTSPACE:user_id} ?%{NOTSPACE:project_id} ?%{NOTSPACE:domain_id} ?%{NOTSPACE:user_domain_id} ?%{NOTSPACE:project_domain_id}\\] %{IPV4:client.address}(,%{IPV4:internal_ip})? \"%{WORD:request_method} %{NOTSPACE:request_path} HTTP/%{NOTSPACE}\" %{NOTSPACE} %{NUMBER:response}?( ).*%{NOTSPACE} %{NUMBER:content_length} %{NOTSPACE} %{BASE10NUM:request_time:float} ?%{NOTSPACE} ?%{NOTSPACE:agent}", true), "upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{TIMESTAMP_ISO8601:timestamp} %{NOTSPACE} %{NOTSPACE:loglevel} %{NOTSPACE:process} (\\[)?(req-)%{NOTSPACE:request_id} ?(g%{NOTSPACE:global_request_id}) ?%{NOTSPACE:user_id} ?%{NOTSPACE:project_id} ?%{NOTSPACE:domain_id} ?%{NOTSPACE:user_domain_id} ?%{NOTSPACE:project_domain_id}\\]", true), "upsert")

transform/non_openstack:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "sentry"
        - resource.attributes["k8s.deployment.name"] == "arc-api"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{IP:remote_addr} %{NOTSPACE:ident} %{NOTSPACE:auth} \\[%{HAPROXYDATE:timestamp}\\] \"%{WORD:request_method} %{NOTSPACE:request_path} %{NOTSPACE:httpversion}\" %{NUMBER:response} %{NUMBER:content_length} %{QUOTEDSTRING:url} \"%{GREEDYDATA:user_agent}\"?( )?(%{BASE10NUM:request_time:float})", true, ["HAPROXYDATE=%{MONTHDAY}/%{MONTH}/%{YEAR}:%{HAPROXYTIME}.%{INT}", "HAPROXYTIME=%{HOUR}:%{MINUTE}(?::%{SECOND})"]),"upsert")

transform/network_generic_ssh_exporter:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "network-generic-ssh-exporter"
      statements:
        - merge_maps(cache, ParseJSON(body), "upsert") where IsMatch(body, "^\\{")
        - set(attributes["loglevel"], cache["level"])
        - set(attributes["ts"], cache["ts"])
        - set(attributes["msg"], cache["msg"])
        - set(attributes["caller"], cache["caller"])
        - set(attributes["ip"], cache["address"])
        - set(attributes["command"], cache["command"])
        - set(attributes["metric"], cache["metric"])

transform/snmp_exporter:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.deployment.name"] == "snmp-exporter"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "ts=%{TIMESTAMP_ISO8601:timestamp} caller=%{NOTSPACE} level=%{NOTSPACE:loglevel} auth=%{NOTSPACE:snmp_auth} target=%{IP:snmp_ip} source_address=(?:%{GREEDYDATA:source}) worker=(?:%{NUMBER}) module=%{NOTSPACE:snmp_module} msg=\"%{GREEDYDATA:snmp_error}\" err=\"%{GREEDYDATA} %{IP}%{NOTSPACE} %{GREEDYDATA:snmp_reason}\"", true), "upsert")

transform/elektra:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.deployment.name"] == "elektra"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "\\[%{NOTSPACE:request}\\] %{WORD} %{WORD:method} \"%{NOTSPACE:url} %{WORD} %{IP:ip} %{WORD} %{TIMESTAMP_ISO8601:timestamp}", true), "upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "\\[%{NOTSPACE:request}\\] %{WORD} %{NUMBER:response}", true), "upsert")
        - merge_maps(attributes, ExtractGrokPatterns(body, "\\[%{NOTSPACE:request}\\]", true), "upsert")

transform/keystone_api:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "keystone-api"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{DATE_EU:timestamp} %{TIME:timestamp} %{NUMBER} %{NOTSPACE:loglevel} %{NOTSPACE:component} \\[%{NOTSPACE:requestid} %{NOTSPACE:global_request_id} usr %{NOTSPACE:usr} prj %{NOTSPACE:prj} dom %{NOTSPACE:dom} usr-dom %{NOTSPACE:usr_domain} prj-dom %{NOTSPACE:project_domain_id}\\] %{GREEDYDATA}'%{WORD:method} %{URIPATH:pri_path}' %{WORD:action}", true), "upsert")

transform/swift_proxy:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.daemonset.name"] == "swift-proxy-cluster-3"
        - resource.attributes["app.label.component"] == "swift-servers"
      statements:
        - merge_maps(attributes, ExtractGrokPatterns(body, "%{SYSLOGTIMESTAMP:date} %{HOSTNAME:host} %{WORD}.%{LOGLEVEL} %{SYSLOGPROG}%{NOTSPACE} %{HOSTNAME:client.address} %{HOSTNAME:remote_addr} %{NOTSPACE:datetime} %{WORD:request_method} %{NOTSPACE:request_path}?( )?(%{NOTSPACE:request_param}) ?(%{NOTSPACE:protocol})?( )%{NUMBER:response} %{NOTSPACE} %{NOTSPACE:user_agent} %{NOTSPACE:auth_token} %{NOTSPACE:bytes_recvd} %{NOTSPACE:bytes_sent} %{NOTSPACE:client.etag} %{NOTSPACE:transaction_id} %{NOTSPACE:headers} %{BASE10NUM:request_time} %{NOTSPACE:source} %{NOTSPACE:log_info} %{BASE10NUM:request_start_time} %{BASE10NUM:request_end_time} %{NOTSPACE:policy_index}", true), "upsert")
        - set(attributes["bytes_recvd"], 0) where attributes["bytes_recvd"] == "-"
        - set(attributes["bytes_sent"], 0) where attributes["bytes_sent"] == "-"


attributes/swift_proxy:
  actions:
    - key: auth_token
      action: delete

{{- end }}

{{- define "openstack.exporter" }}
opensearch/failover_a_swift:
  http:
    auth:
      authenticator: basicauth/failover_a
    endpoint: {{ .Values.openTelemetryPlugin.openTelemetry.openSearchLogs.endpoint }}
  logs_index: ${index}-swift-datastream
opensearch/failover_b_swift:
  http:
    auth:
      authenticator: basicauth/failover_b
    endpoint: {{ .Values.openTelemetryPlugin.openTelemetry.openSearchLogs.endpoint }}
  logs_index: ${index}-swift-datastream
{{- end }}

{{- define "openstack.pipeline" }}
logs/forward_swift:
  receivers: [forward/swift]
  processors: [batch]
  exporters: [failover/opensearch_swift]

logs/failover_a_swift:
  receivers: [failover/opensearch_swift]
  processors: [attributes/failover_username_a]
  exporters: [opensearch/failover_a_swift]
logs/failover_b_swift:
  receivers: [failover/opensearch_swift]
  processors: [attributes/failover_username_b]
  exporters: [opensearch/failover_b_swift]

logs/containerd:
  receivers: [filelog/containerd]
  processors: [k8sattributes,attributes/cluster,transform/ingress,transform/neutron_agent,transform/neutron_errors,transform/openstack_ironic,transform/openstack_manila,transform/openstack_api,transform/non_openstack,transform/network_generic_ssh_exporter,transform/snmp_exporter,transform/elektra,transform/keystone_api]
  exporters: [forward]

logs/containerd-swift:
  receivers: [filelog/containerd_swift]
  processors: [k8sattributes,attributes/cluster,transform/ingress,transform/swift_proxy,attributes/swift_proxy]
  exporters: [forward/swift]
{{- end }}
