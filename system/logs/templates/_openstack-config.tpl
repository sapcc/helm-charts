{{- define "openstack.receiver" }}
filelog/containerd:
  include_file_path: true
  include: [ /var/log/pods/*/*/*.log ]
  exclude: [ /var/log/pods/logs_logs-*/*/*.log, /var/log/pods/logs_fluent*/*/*.log, /var/log/pods/dns-recursor_unbound*/*/*.log, /var/log/pods/kube-system_wormhole*/*/*.log ]
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
{{- end }}

{{- define "openstack.transform" }}
transform/ingress:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["app.label.name"] == "ingress-nginx"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{IP:client.address} %{NOTSPACE:client.ident} %{NOTSPACE:client.auth} \\[%{HTTPDATE:httpdate}\\] \"%{WORD:request.method} %{NOTSPACE:request.path} %{WORD:network.protocol.name}/%{NOTSPACE:network.protocol.version}\" %{NUMBER:response} %{NUMBER:content_length:int} %{QUOTEDSTRING} \"%{GREEDYDATA:user_agent}\" %{NUMBER:request.length:int} %{BASE10NUM:request.time:float}( \\[%{NOTSPACE:service}\\])? ?(\\[\\])? %{IP:server.address}\\:%{NUMBER:server.port} %{NUMBER:upstream.response.length:int} %{BASE10NUM:upstream.response.time:float} %{NOTSPACE:upstream.status} %{NOTSPACE:request.id}", true),"upsert")
        - set(log.attributes["network.protocol.name"], ConvertCase(log.attributes["network.protocol.name"], "lower")) where log.attributes["network.protocol.name"] != nil
        - set(log.attributes["config.parsed"], "ingress-nginx") where log.attributes["client.address"] != nil

transform/neutron_agent:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "neutron-metadata-agent"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "(%{TIMESTAMP_ISO8601}|)( )?%{TIMESTAMP_ISO8601}.%{NOTSPACE}? %{NUMBER:pid} %{WORD:log.level} %{NOTSPACE:logger} \\[-\\] %{GREEDYDATA} %{NOTSPACE} %{WORD:request.method} %{NOTSPACE} %{QUOTEDSTRING:request.path} %{NOTSPACE} %{NUMBER:request.status} %{NOTSPACE} %{IPV4:client.address} %{NOTSPACE} %{NOTSPACE:project.id} %{NOTSPACE} %{NOTSPACE:openstack.network.id} %{NOTSPACE} %{NOTSPACE:openstack.router.id} %{NOTSPACE} %{NOTSPACE:openstack.instance.id} %{NOTSPACE} %{BASE10NUM:request.duration} %{NOTSPACE} %{QUOTEDSTRING:user_agent}", true),"upsert")

transform/neutron_errors:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "neutron-server"
        - resource.attributes["k8s.container.name"] == "neutron-asr1k"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{TIMESTAMP_ISO8601} %{NOTSPACE} %{NOTSPACE:log.level} %{NOTSPACE:logger} (\\[)?(req-)%{NOTSPACE:request.id} ?(g%{NOTSPACE:global.request.id}) ?%{NOTSPACE:user.id} ?%{NOTSPACE:project.id} ?%{NOTSPACE:domain.id} ?%{NOTSPACE:user.domain.id} ?%{NOTSPACE:project.domain.id}\\] %{IPV4:client.address} \"%{WORD:request.method} %{NOTSPACE:request.path} HTTP/%{NOTSPACE}\" %{NOTSPACE} %{NUMBER:response}?( ).*%{NOTSPACE} %{NUMBER:content_length:int} %{NOTSPACE} %{BASE10NUM:request.time:float} %{NOTSPACE} %{NOTSPACE:agent}", true),"upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{TIMESTAMP_ISO8601} %{NOTSPACE} %{NOTSPACE:log.level} %{NOTSPACE:logger} (\\[)?(req-)%{NOTSPACE:request.id} ?(g%{NOTSPACE:global.request.id}) ?%{NOTSPACE:user.id} ?%{NOTSPACE:project.id} ?%{NOTSPACE:domain.id} ?%{NOTSPACE:user.domain.id} ?%{NOTSPACE:project.domain.id}\\]", true), "upsert")
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
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{TIMESTAMP_ISO8601} %{NOTSPACE} %{NOTSPACE:log.level} %{NOTSPACE:logger} (\\[)?(req-)%{NOTSPACE:request.id} ?(g%{NOTSPACE:global.request.id}) ?%{NOTSPACE:user.id} ?%{NOTSPACE:project.id} ?%{NOTSPACE:domain.id} ?%{NOTSPACE:user.domain.id} ?%{NOTSPACE:project.domain.id}\\] %{IPV4:ip.client}(,%{IPV4:ip.target})? \"%{WORD:request.method} %{NOTSPACE:request.path} HTTP/%{NOTSPACE}\" %{NOTSPACE} %{NUMBER:response}?( ).*%{NOTSPACE} %{NUMBER:content_length:int} %{NOTSPACE} %{BASE10NUM:request.time:float} ?%{NOTSPACE} ?%{NOTSPACE:agent}", true), "upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{TIMESTAMP_ISO8601} %{NOTSPACE} %{NOTSPACE:log.level} %{NOTSPACE:logger} (\\[)?(req-)%{NOTSPACE:request.id} ?(g%{NOTSPACE:global.request.id}) ?%{NOTSPACE:user.id} ?%{NOTSPACE:project.id} ?%{NOTSPACE:domain.id} ?%{NOTSPACE:user.domain.id} ?%{NOTSPACE:project.domain.id}\\]", true), "upsert")

transform/non_openstack:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "sentry"
        - resource.attributes["k8s.deployment.name"] == "arc-api"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{IP:ip.target} %{NOTSPACE:ident} %{NOTSPACE:auth} \\[%{HAPROXYDATE:proxy_date}\\] \"%{WORD:request.method} %{NOTSPACE:request.path} %{NOTSPACE:httpversion}\" %{NUMBER:response} %{NUMBER:content_length:int} %{QUOTEDSTRING:url} \"%{GREEDYDATA:user_agent}\"?( )?(%{BASE10NUM:request.time:float})", true, ["HAPROXYDATE=%{MONTHDAY}/%{MONTH}/%{YEAR}:%{HAPROXYTIME}.%{INT}", "HAPROXYTIME=%{HOUR}:%{MINUTE}(?::%{SECOND})"]),"upsert")

transform/network_generic_ssh_exporter:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "network-generic-ssh-exporter"
      statements:
        - merge_maps(log.cache, ParseJSON(log.body), "upsert") where IsMatch(log.body, "^\\{")
        - set(log.attributes["log.level"], log.cache["level"])
        - set(log.attributes["ts"], log.cache["ts"])
        - set(log.attributes["msg"], log.cache["msg"])
        - set(log.attributes["caller"], log.cache["caller"])
        - set(log.attributes["ip.target"], log.cache["address"])
        - set(log.attributes["command"], log.cache["command"])
        - set(log.attributes["metric"], log.cache["metric"])

transform/perses:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "perses"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "time=%{QUOTEDSTRING} level=%{WORD:log.level} msg=%{GREEDYDATA:msg}", true),"upsert")
        - set(log.attributes["config.parsed"], "perses")

transform/coredns_api:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.deployment.name"] == "coredns-api"
      statements:
        - merge_maps(log.cache, ParseJSON(log.body), "upsert") where IsMatch(log.body, "^\\{")
        - set(log.attributes["log.level"], log.cache["level"])
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
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "time=%{TIMESTAMP_ISO8601} level=%{NOTSPACE:log.level} source=%{NOTSPACE} msg=\"%{GREEDYDATA:snmp_error}\" auth=%{NOTSPACE:snmp_auth} target=%{IP:ip.target} source_address=(?:%{GREEDYDATA:source}) worker=(?:%{NUMBER}) module=%{NOTSPACE:snmp_module} err=\"%{GREEDYDATA} %{IP}%{NOTSPACE} %{GREEDYDATA:snmp_reason}\"", true), "upsert")

transform/kvm-ha-service:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
      - resource.attributes["k8s.container.name"] == "kvm-ha-service-container"
      statements:
      - set(log.attributes["kvm_ha"], ParseKeyValue(target=log.body)) where IsMatch(log.body, "^time")

transform/elektra:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.deployment.name"] == "elektra"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "\\[%{NOTSPACE:request.id}\\] %{WORD} %{WORD:request.method} \"%{NOTSPACE:url} %{WORD} %{IP:ip.client} %{WORD} %{TIMESTAMP_ISO8601}", true), "upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "\\[%{NOTSPACE:request.id}\\] %{WORD} %{NUMBER:response}", true), "upsert")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "\\[%{NOTSPACE:request.id}\\]", true), "upsert")

transform/keystone_api:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.container.name"] == "keystone-api"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{DATE_EU} %{TIME} %{NUMBER} %{NOTSPACE:log.level} %{NOTSPACE:component} \\[%{NOTSPACE:request.id} %{NOTSPACE:global.request.id} usr %{NOTSPACE:user.id} prj %{NOTSPACE:project.id} dom %{NOTSPACE:domain.id} usr-dom %{NOTSPACE:user.domain.id} prj-dom %{NOTSPACE:project.domain.id}\\] %{GREEDYDATA}'%{WORD:request.method} %{URIPATH:uri}' %{WORD:action}", true), "upsert")

transform/keystone_api_json:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.cluster.name"] == "qa-de-2"
        - resource.attributes["k8s.container.name"] == "keystone-api"
      statements:
        - merge_maps(log.cache, ParseJSON(log.body), "upsert") where IsMatch(log.body, "^\\{.*\\}$")
        - set(log.time, Time(log.cache["asctime"], "%Y-%m-%d %H:%M:%S,%L")) where log.cache["asctime"] != nil
        - set(log.attributes["msg"], log.cache["message"])
        - set(log.severity_text, log.cache["levelname"])
        - set(log.attributes["infra.container.component"], log.cache["name"])
        - set(log.attributes["infra.request.id"], log.cache["context"]["request_id"])
        - set(log.attributes["infra.request.id"], log.cache["request_id"]) where log.cache["request_id"] != nil and log.attributes["infra.request.id"] == nil
        - set(log.attributes["infra.global.request.id"], log.cache["context"]["global_request_id"])
        - set(log.attributes["user.id"], log.cache["context"]["user"])
        - set(log.attributes["user.id"], log.cache["user_id"]) where log.cache["user_id"] != nil and log.attributes["user.id"] == nil
        - set(log.attributes["user.name"], log.cache["context"]["user_name"])
        - set(log.attributes["domain.project.id"], log.cache["context"]["project_id"])
        - set(log.attributes["domain.project.id"], log.cache["project_id"]) where log.cache["project_id"] != nil and log.attributes["domain.project.id"] == nil
        - set(log.attributes["domain.project.name"], log.cache["context"]["project_name"])
        - set(log.attributes["domain.id"], log.cache["context"]["project_domain"])
        - set(log.attributes["client.address"], log.cache["client_ip"])
        - set(log.attributes["client.address"], log.cache["remote_addr"]) where log.cache["remote_addr"] != nil and log.attributes["client.address"] == nil
        - set(log.attributes["http.request.method"], log.cache["method"])
        - set(log.attributes["http.url.path"], log.cache["uri"])
        - set(log.attributes["network.protocol.version"], log.cache["protocol"])
        - set(log.attributes["http.response.status_code"], log.cache["status"])
        - set(log.attributes["http.user_agent.original"], log.cache["user_agent"])
        - set(log.attributes["log.kind"], "cadf_action") where IsMatch(log.attributes["msg"], "^\\s*cadf action for.*")
        - set(log.attributes["log.kind"], "target_type_uri") where IsMatch(log.attributes["msg"], "^\\s*target type URI of requests.*")
        - set(log.attributes["log.kind"], "authentication") where IsMatch(log.attributes["msg"], "^\\s*Authenticating.*")
        - set(log.attributes["log.kind"], "keystone_exception_UserNotFound") where IsMatch(log.attributes["infra.container.component"], "keystone\\.auth\\.plugins\\.core")
        - set(log.attributes["log.kind"], "keystone_middleware_lifesaver") where log.attributes["infra.container.component"] == "cc\\.keystone\\.middleware\\.lifesaver" and IsMatch(log.attributes["msg"], ".*has a remaining credit of.*")
        - set(log.attributes["log.kind"], "keystone_exception_Unauthorized") where IsMatch(log.attributes["msg"], "^\\s*Authorization failed\\..*")
        - merge_maps(log.attributes, ExtractGrokPatterns(log.attributes["msg"], "^\\s*cadf action for '%{NOTSPACE:http.request.method} %{URIPATH:http.url.path}' is '%{NOTSPACE:event.action}'", true), "upsert") where log.attributes["log.kind"] == "cadf_action"
        - merge_maps(log.attributes, ExtractGrokPatterns(log.attributes["msg"], "^\\s*target type URI of requests '%{NOTSPACE:http.request.method} %{URIPATH:http.url.path}' is '%{NOTSPACE:target.type_uri}'", true), "upsert") where log.attributes["log.kind"] == "target_type_uri"
        - merge_maps(log.attributes, ExtractGrokPatterns(log.attributes["msg"], "^\\s*Authenticating %{NOTSPACE:user.name}@%{NOTSPACE:domain.name}\\.\\.", true), "upsert") where log.attributes["log.kind"] == "authentication"
        - merge_maps(log.attributes, ExtractGrokPatterns(log.attributes["msg"], "^\\s*Could not find user:[\\s]+%{NOTSPACE:user.id}\\.", true), "upsert") where log.attributes["log.kind"] == "keystone_exception_UserNotFound"
        - merge_maps(log.attributes, ExtractGrokPatterns(log.attributes["msg"], "(?:AC-)%{NOTSPACE:user.id}\\s+has a remaining credit of %{NUMBER} - request %{WORD:http.request.method} %{NOTSPACE:http.url.path} returned %{NUMBER:http.response.status_code:int}", true), "upsert") where log.attributes["msg"] != nil and log.attributes["log.kind"] == "keystone_middleware_lifesaver"
        - merge_maps(log.attributes, ExtractGrokPatterns(log.attributes["msg"], "Authorization failed. The request you have made requires authentication. from %{IP:client.address}", true), "upsert") where log.attributes["log.kind"] == "keystone_exception_Unauthorized"
        - delete_key(log.attributes, "log.kind")
        - delete_key(log.attributes, "msg")

filter/hermes_logstash:
  error_mode: ignore
  logs:
    log_record:
      - 'IsMatch(body, ".*Authorization: Basic.*")'

transform/swift_proxy:
  error_mode: ignore
  log_statements:
    - context: log
      conditions:
        - resource.attributes["k8s.daemonset.name"] == "swift-proxy-cluster-3"
        - resource.attributes["app.label.component"] == "swift-servers"
      statements:
        - merge_maps(log.attributes, ExtractGrokPatterns(log.body, "%{SYSLOGTIMESTAMP:date} %{HOSTNAME:host} %{WORD}.%{LOGLEVEL} %{SYSLOGPROG}%{NOTSPACE} %{HOSTNAME:client.address} %{HOSTNAME:server.ip} %{NOTSPACE:datetime} %{WORD:request.method} %{NOTSPACE:request.path}?( )?(%{NOTSPACE:request.param}) ?(%{NOTSPACE:protocol})?( )%{NUMBER:response} %{NOTSPACE} %{NOTSPACE:user_agent} %{NOTSPACE:auth_token} %{NOTSPACE:bytes_recvd} %{NOTSPACE:bytes_sent} %{NOTSPACE:client.etag} %{NOTSPACE:transaction_id} %{NOTSPACE:headers} %{BASE10NUM:request.time:float} %{NOTSPACE:source} %{NOTSPACE:log_info} %{BASE10NUM:request.start.time} %{BASE10NUM:request.end.time} %{NOTSPACE:policy_index}", true), "upsert")
        - set(log.attributes["bytes_recvd"], 0) where log.attributes["bytes_recvd"] == "-"
        - set(log.attributes["bytes_sent"], 0) where log.attributes["bytes_sent"] == "-"


attributes/swift_proxy:
  actions:
    - key: auth_token
      action: delete

{{- end }}

{{- define "openstack.exporter" }}
opensearch/swift_failover_a:
  http:
    auth:
      authenticator: basicauth/failover_a
    endpoint: {{ .Values.openTelemetryPlugin.openTelemetry.openSearchLogs.endpoint }}
  logs_index: ${index}-swift-datastream
  retry_on_failure:
    enabled: true
    initial_interval: 1s
    max_interval: 5s
    max_elapsed_time: 30s
  timeout: 10s
opensearch/swift_failover_b:
  http:
    auth:
      authenticator: basicauth/failover_b
    endpoint: {{ .Values.openTelemetryPlugin.openTelemetry.openSearchLogs.endpoint }}
  logs_index: ${index}-swift-datastream
  retry_on_failure:
    enabled: true
    initial_interval: 1s
    max_interval: 5s
    max_elapsed_time: 30s
  timeout: 10s
{{- end }}

{{- define "openstack.pipeline" }}
logs/containerd:
  receivers: [filelog/containerd]
  processors: [k8s_attributes,attributes/cluster,transform/ingress,transform/neutron_agent,transform/neutron_errors,transform/openstack_api,transform/non_openstack,transform/network_generic_ssh_exporter,transform/snmp_exporter,transform/elektra,transform/keystone_api,transform/keystone_api_json,transform/kvm-ha-service,transform/coredns_api,transform/perses,filter/hermes_logstash,transform/swift_proxy,attributes/swift_proxy]
  exporters: [routing]

logs/route_swift:
  receivers: [routing]
  processors: [batch]
  exporters: [failover/opensearch_swift]

logs/failover_a_swift:
  receivers: [failover/opensearch_swift]
  processors: [attributes/failover_username_a]
  exporters: [opensearch/swift_failover_a]

logs/failover_b_swift:
  receivers: [failover/opensearch_swift]
  processors: [attributes/failover_username_b]
  exporters: [opensearch/swift_failover_b]
{{- end }}
