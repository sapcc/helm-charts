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
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{IP:client.address} %{NOTSPACE:client.ident} %{NOTSPACE:client.auth} \\[%{HTTPDATE:httpdate}\\] \"%{WORD:request.method} %{NOTSPACE:request.path} %{WORD:network.protocol.name}/%{NOTSPACE:network.protocol.version}\" %{NUMBER:response} %{NUMBER:content_length:int} %{QUOTEDSTRING} \"%{GREEDYDATA:user_agent}\" %{NUMBER:request.length:int} %{BASE10NUM:request.time:float}( \\[%{NOTSPACE:service}\\])? ?(\\[\\])? %{IP:server.address}\\:%{NUMBER:server.port} %{NUMBER:upstream_response_length:int} %{BASE10NUM:upstream_response_time:float} %{NOTSPACE:upstream_status} %{NOTSPACE:request.id}", true),"upsert")
        - set(log.attributes["network.protocol.name"], ConvertCase(log.attributes["network.protocol.name"], "lower")) where log.attributes["network.protocol.name"] != nil
        - set(log.attributes["config.parsed"], "ingress-nginx") where log.attributes["client.address"] != nil

transform/neutron_agent:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "neutron-network-agent"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{WORD:loglevel} %{NOTSPACE:logger} \\[-\\] %{GREEDYDATA} %{NOTSPACE} %{WORD:request.method} %{NOTSPACE} %{QUOTEDSTRING:request.path} %{NOTSPACE} %{NUMBER:request.status} %{NOTSPACE} %{IPV4:client.address} %{NOTSPACE} %{NOTSPACE:project_id} %{NOTSPACE} %{NOTSPACE:os_network_id} %{NOTSPACE} %{NOTSPACE:os_router_id} %{NOTSPACE} %{NOTSPACE:os_instance_id} %{NOTSPACE} %{BASE10NUM:request.duration} %{NOTSPACE} %{QUOTEDSTRING:user_agent}", true),"upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "(%{TIMESTAMP_ISO8601}|)( )?%{TIMESTAMP_ISO8601}.%{NOTSPACE}? %{NUMBER:pid} %{WORD:loglevel} %{NOTSPACE:logger} \\[-\\] %{GREEDYDATA} %{NOTSPACE} %{WORD:request.method} %{NOTSPACE} %{QUOTEDSTRING:request.path} %{NOTSPACE} %{NUMBER:request.status} %{NOTSPACE} %{IPV4:client.address} %{NOTSPACE %{NOTSPACE:project_id} %{NOTSPACE} %{NOTSPACE:os_network_id} %{NOTSPACE} %{NOTSPACE:os_router_id} %{NOTSPACE} %{NOTSPACE:os_instance_id} %{NOTSPACE} %{BASE10NUM:request.duration} %{NOTSPACE} %{QUOTEDSTRING:user_agent}", true),"upsert")

transform/neutron_errors:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "neutron-server"
        - resource.attributes["k8s.container.name"] == "neutron-asr1k"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{TIMESTAMP_ISO8601} %{NOTSPACE} %{NOTSPACE:loglevel} %{NOTSPACE:logger} (\\[)?(req-)%{NOTSPACE:request.id} ?(g%{NOTSPACE:global_request.id}) ?%{NOTSPACE:user_id} ?%{NOTSPACE:project_id} ?%{NOTSPACE:domain_id} ?%{NOTSPACE:user_domain_id} ?%{NOTSPACE:project_domain_id}\\] %{IPV4:client.address} \"%{WORD:request.method} %{NOTSPACE:request.path} HTTP/%{NOTSPACE}\" %{NOTSPACE} %{NUMBER:response}?( ).*%{NOTSPACE} %{NUMBER:content_length:int} %{NOTSPACE} %{BASE10NUM:request.time:float} %{NOTSPACE} %{NOTSPACE:agent}", true),"upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{TIMESTAMP_ISO8601} %{NOTSPACE} %{NOTSPACE:loglevel} %{NOTSPACE:logger} (\\[)?(req-)%{NOTSPACE:request.id} ?(g%{NOTSPACE:global_request.id}) ?%{NOTSPACE:user_id} ?%{NOTSPACE:project_id} ?%{NOTSPACE:domain_id} ?%{NOTSPACE:user_domain_id} ?%{NOTSPACE:project_domain_id}\\]", true), "upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "Encoutered a requeable lock exception executing %{WORD:neutronTask:string} for model %{WORD:neutronModel:string} on device %{IP:neutronIp:string}", true),"upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "asr1k_exceptions.InconsistentModelException?(:) %{WORD:neutronTask} for model %{WORD:neutronModel} cannot be executed on %{IP:neutronIp}", true),"upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{WORD:neutronTask} for model %{WORD:neutronModel} cannot be executed on %{IP:neutronIp} due to a model/device inconsistency.", true),"upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "Failed to bind port %{UUID:neutronPort:string} on host %{NOTSPACE:neutronHost:string} for vnic_type %{WORD:neutronVnicType:string} using segments", true),"upsert")

transform/openstack_api:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.deployment.name"] == "cinder-api"
        - resource.attributes["k8s.deployment.name"] == "nova-api"
        - resource.attributes["k8s.deployment.name"] == "designate-api"
        - resource.attributes["k8s.deployment.name"] == "barbican-api"
        - resource.attributes["k8s.deployment.name"] == "manila-api"
        - resource.attributes["k8s.deployment.name"] == "ironic-api"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{TIMESTAMP_ISO8601} %{NOTSPACE} %{NOTSPACE:loglevel} %{NOTSPACE:logger} (\\[)?(req-)%{NOTSPACE:request.id} ?(g%{NOTSPACE:global_request.id}) ?%{NOTSPACE:user_id} ?%{NOTSPACE:project_id} ?%{NOTSPACE:domain_id} ?%{NOTSPACE:user_domain_id} ?%{NOTSPACE:project_domain_id}\\] %{IPV4:client.address}(,%{IPV4:internal_ip})? \"%{WORD:request.method} %{NOTSPACE:request.path} HTTP/%{NOTSPACE}\" %{NOTSPACE} %{NUMBER:response}?( ).*%{NOTSPACE} %{NUMBER:content_length:int} %{NOTSPACE} %{BASE10NUM:request.
        time:float} ?%{NOTSPACE} ?%{NOTSPACE:agent}", true), "upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{TIMESTAMP_ISO8601} %{NOTSPACE} %{NOTSPACE:loglevel} %{NOTSPACE:logger} (\\[)?(req-)%{NOTSPACE:request.id} ?(g%{NOTSPACE:global_request.id}) ?%{NOTSPACE:user_id} ?%{NOTSPACE:project_id} ?%{NOTSPACE:domain_id} ?%{NOTSPACE:user_domain_id} ?%{NOTSPACE:project_domain_id}\\]", true), "upsert")

transform/non_openstack:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "sentry"
        - resource.attributes["k8s.deployment.name"] == "arc-api"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{IP:remote_addr} %{NOTSPACE:ident} %{NOTSPACE:auth} \\[%{HAPROXYDATE:proxy_date}\\] \"%{WORD:request.method} %{NOTSPACE:request.path} %{NOTSPACE:httpversion}\" %{NUMBER:response} %{NUMBER:content_length:int} %{QUOTEDSTRING:url} \"%{GREEDYDATA:user_agent}\"?( )?(%{BASE10NUM:request.time:float})", true, ["HAPROXYDATE=%{MONTHDAY}/%{MONTH}/%{YEAR}:%{HAPROXYTIME}.%{INT}", "HAPROXYTIME=%{HOUR}:%{MINUTE}(?::%{SECOND})"]),"upsert")

transform/network_generic_ssh_exporter:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "network-generic-ssh-exporter"
      statements:
        - merge_maps(log.cache, ParseJSON(log.body), "upsert") where IsMatch(log.body, "^\\{")
        - set(log.attributes["loglevel"], log.cache["level"])
        - set(log.attributes["ts"], log.cache["ts"])
        - set(log.attributes["msg"], log.cache["msg"])
        - set(log.attributes["caller"], log.cache["caller"])
        - set(log.attributes["ip"], log.cache["address"])
        - set(log.attributes["command"], log.cache["command"])
        - set(log.attributes["metric"], log.cache["metric"])

transform/coredns_api:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.deployment.name"] == "coredns-api"
      statements:
        - set(log.attributes["loglevel"], log.cache["level"])
        - set(log.attributes["time"], log.cache["time"])
        - set(log.attributes["request.id"], log.cache["request-id"])
        - set(log.attributes["duration"], log.cache["duration"])
        - set(log.attributes["component"], log.cache["component"])
        - set(log.attributes["action"], log.cache["action"])
        - set(log.attributes["msg"], log.cache["msg"])
        - set(log.attributes["error"], log.cache["error"])
        - set(log.attributes["returned"], log.cache["returned"])
        - set(log.attributes["request.status"], log.cache["status"])

transform/snmp_exporter:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.deployment.name"] == "snmp-exporter"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "time=%{TIMESTAMP_ISO8601} level=%{NOTSPACE:loglevel} source=%{NOTSPACE} msg=\"%{GREEDYDATA:snmp_error}\" auth=%{NOTSPACE:snmp_auth} target=%{IP:snmp_ip} source_address=(?:%{GREEDYDATA:source}) worker=(?:%{NUMBER}) module=%{NOTSPACE:snmp_module} err=\"%{GREEDYDATA} %{IP}%{NOTSPACE} %{GREEDYDATA:snmp_reason}\"", true), "upsert")

transform/kvm-ha-service:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
      - resource.attributes["k8s.container.name"] == "kvm-ha-service-container"
      statements:
      - set(attributes["kvm_ha"], ParseKeyValue(target=log.body)) where IsMatch(log.body, "^time")

transform/elektra:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.deployment.name"] == "elektra"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "\\[%{NOTSPACE:
        
        
        
        
        
        }\\] %{WORD} %{WORD:method} \"%{NOTSPACE:url} %{WORD} %{IP:ip} %{WORD} %{TIMESTAMP_ISO8601}", true), "upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "\\[%{NOTSPACE:request.id}\\] %{WORD} %{NUMBER:response}", true), "upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "\\[%{NOTSPACE:request.id}\\]", true), "upsert")

transform/keystone_api:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "keystone-api"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{DATE_EU} %{TIME} %{NUMBER} %{NOTSPACE:loglevel} %{NOTSPACE:component} \\[%{NOTSPACE:request.id} %{NOTSPACE:global.request.id} usr %{NOTSPACE:usr} prj %{NOTSPACE:prj} dom %{NOTSPACE:dom} usr-dom %{NOTSPACE:usr_domain} prj-dom %{NOTSPACE:project_domain_id}\\] %{GREEDYDATA}'%{WORD:method} %{URIPATH:pri_path}' %{WORD:action}", true), "upsert")

transform/swift_proxy:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.daemonset.name"] == "swift-proxy-cluster-3"
        - resource.attributes["app.label.component"] == "swift-servers"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{SYSLOGTIMESTAMP:date} %{HOSTNAME:host} %{WORD}.%{LOGLEVEL} %{SYSLOGPROG}%{NOTSPACE} %{HOSTNAME:client.address} %{HOSTNAME:remote_addr} %{NOTSPACE:datetime} %{WORD:request.method} %{NOTSPACE:request.path}?( )?(%{NOTSPACE:request.param}) ?(%{NOTSPACE:protocol})?( )%{NUMBER:response} %{NOTSPACE} %{NOTSPACE:user_agent} %{NOTSPACE:auth_token} %{NOTSPACE:bytes_recvd} %{NOTSPACE:bytes_sent} %{NOTSPACE:client.etag} %{NOTSPACE:transaction_id} %{NOTSPACE:headers} %{BASE10NUM:request.time:float} %{NOTSPACE:source} %{NOTSPACE:log_info} %{BASE10NUM:request.start.time} %{BASE10NUM:request.end.
        time} %{NOTSPACE:policy_index}", true), "upsert")
        - set(log.attributes["bytes_recvd"], 0) where log.attributes["bytes_recvd"] == "-"
        - set(log.attributes["bytes_sent"], 0) where log.attributes["bytes_sent"] == "-"


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
  retry_on_failure:
    enabled: true
    max_elapsed_time: 0s
  sending_queue:
    block_on_overflow: true
    enabled: true
    num_consumers: 10
    queue_size: 10000
    sizer: requests
  timeout: 30s
opensearch/failover_b_swift:
  http:
    auth:
      authenticator: basicauth/failover_b
    endpoint: {{ .Values.openTelemetryPlugin.openTelemetry.openSearchLogs.endpoint }}
  logs_index: ${index}-swift-datastream
  retry_on_failure:
    enabled: true
    max_elapsed_time: 0s
  sending_queue:
    block_on_overflow: true
    enabled: true
    num_consumers: 10
    queue_size: 10000
    sizer: requests
  timeout: 30s
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
  processors: [k8sattributes,attributes/cluster,transform/ingress,transform/neutron_agent,transform/neutron_errors,transform/openstack_api,transform/non_openstack,transform/network_generic_ssh_exporter,transform/snmp_exporter,transform/elektra,transform/keystone_api,transform/kvm-ha-service,transform/coredns_api]
  exporters: [forward]

logs/containerd-swift:
  receivers: [filelog/containerd_swift]
  processors: [k8sattributes,attributes/cluster,transform/ingress,transform/swift_proxy,attributes/swift_proxy]
  exporters: [forward/swift]
{{- end }}
