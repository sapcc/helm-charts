<filter kubernetes.var.log.containers.cinder**  kubernetes.var.log.containers.nova** kubernetes.var.log.containers.designate** kubernetes.var.log.containers.barbican**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern (%{TIMESTAMP_ISO8601:logtime}|)( )?%{TIMESTAMP_ISO8601:timestamp}.%{NOTSPACE}? %{NUMBER:pid} %{WORD:loglevel} %{NOTSPACE:logger} (\[)?(req-)?%{NOTSPACE:requestid} (greq-%{UUID:global_requestid})?
    custom_pattern_path /fluentd/etc/pattern
  </parse>
</filter>

<filter kubernetes.var.log.containers.network-generic-ssh-exporter**>
  @type parser
  @id ssh_json
  key_name log
  reserve_data true
  <parse>
    @type json
  </parse>
</filter>

<filter kubernetes.var.log.containers.network-generic-ssh-exporter**>
  @type parser
  @id ssh_grok
  key_name msg
  <parse>
    @type grok
    grok_failure_key grokstatus_ssh_exporter
    <grok>
      pattern %{GREEDYDATA}: %{GREEDYDATA:ssh_reason} \^%{GREEDYDATA}on %{IPORHOST:ssh_ip}\:
    </grok>
    <grok>
      pattern Error parsing metric: %{GREEDYDATA:ssh_reason}\, address: %{IPORHOST:ssh_ip}
    </grok>
    <grok>
      pattern %{GREEDYDATA:ssh_reason}: dial tcp %{IPORHOST:ssh_ip}
    </grok>
  </parse>
</filter>

<filter kubernetes.var.log.containers.neutron**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_failure_key grokstatus_neutron
    <grok>
      pattern Encoutered a requeable lock exception executing %{WORD:neutronTask:string} for model %{WORD:neutronModel:string} on device %{IP:neutronIp:string}
    </grok>
    <grok>
      pattern asr1k_exceptions.InconsistentModelException: %{WORD:neutronTask} for model %{WORD:neutronModel} cannot be executed on %{IP:neutronIp}
    </grok>
    <grok>
      pattern %{WORD:neutronTask} for model %{WORD:neutronModel} cannot be executed on %{IP:neutronIp} due to a model/device inconsistency.
    </grok>
    <grok>
      pattern Failed to bind port %{UUID:neutronPort:string} on host %{NOTSPACE:neutronHost:string} for vnic_type %{WORD:neutronVnicType:string} using segments
    </grok>
  </parse>
</filter>

<filter kubernetes.var.log.containers.neutron-network-agent**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_failure_key grokstatus_neutron_network_agent
    grok_pattern (%{TIMESTAMP_ISO8601:logtime}|)( )?%{TIMESTAMP_ISO8601:timestamp}.%{NOTSPACE}? %{NUMBER:pid} %{WORD:loglevel} %{NOTSPACE:logger} \[-] %{GREEDYDATA} method: %{WORD:uri_method} path: \"%{NOTSPACE:uri_path}\" status: %{NUMBER:uri_status} client-ip: %{IPV4:client_ip} project-id: %{NOTSPACE:project_id} os-network-id: %{NOTSPACE:os_network_id} os-router-id: %{NOTSPACE:os_router_id} os-instance-id: %{NOTSPACE:os_instance_id} req-duration: %{BASE10NUM:uri_req_duration:float} user-agent: \"%{NOTSPACE:user_agent}\"
    custom_pattern_path /fluentd/etc/pattern
  </parse>
</filter>

<filter kubernetes.var.log.containers.neutron-server**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_failure_key grokstatus_neutron_server
    grok_pattern %{TIMESTAMP_ISO8601:timestamp} %{NOTSPACE} %{NOTSPACE:loglevel} %{NOTSPACE:process} (\[)?(req-)%{NOTSPACE:requestid} ?(greq-%{UUID:global_requestid})? ?%{NOTSPACE:userid} ?%{NOTSPACE:projectid} ?%{NOTSPACE:domainid} ?%{NOTSPACE:user_domainid} ?%{NOTSPACE:project_domainid}] %{IPV4:client_ip} "%{WORD:request_method} %{NOTSPACE:request_path} HTTP/%{NOTSPACE}" status: %{NUMBER:response}?( ).*len: %{NUMBER:content_length:integer} time: %{BASE10NUM:request_time:float} agent: %{NOTSPACE:agent}
    custom_pattern_path /fluentd/etc/pattern
  </parse>
</filter>

<filter kubernetes.var.log.containers.ironic-api**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{TIMESTAMP_ISO8601:timestamp} %{NOTSPACE} %{NOTSPACE:loglevel} %{NOTSPACE:process} \[%{GREEDYDATA}\] ?([0-9.,].*) "%{WORD:request_method} %{NOTSPACE:request_path} HTTP/%{NOTSPACE}" status: %{NUMBER:response}?( ).*len: %{NUMBER:content_length:integer} time: %{BASE10NUM:request_time:float}
    custom_pattern_path /fluentd/etc/pattern
  </parse>
</filter>

<filter kubernetes.var.log.containers.glance**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{DATE_EU:timestamp}%{SPACE}%{GREEDYDATA}"%{WORD:method}%{SPACE}%{IMAGE_METHOD:path}%{NOTSPACE}%{SPACE}%{NOTSPACE:httpversion}"%{SPACE}%{NUMBER:response}
    custom_pattern_path /fluentd/etc/pattern
  </parse>
</filter>

<filter kubernetes.var.log.containers.manila-api** kubernetes.var.log.containers.manila-scheduler** kubernetes.var.log.containers.manila-share-netapp**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern (%{TIMESTAMP_ISO8601:logtime}|)( )?%{TIMESTAMP_ISO8601:access_timestamp}.%{NOTSPACE} %{NUMBER:pid} %{NOTSPACE:log_level} %{NOTSPACE:program} (\[?)%{NOTSPACE:request_id} %{NOTSPACE:user_id} %{NOTSPACE:project_id} %{NOTSPACE:domain_id} %{NOTSPACE:id1} %{REQUESTID:id2}(\]?) %{GREEDYDATA:log_request}
    custom_pattern_path /fluentd/etc/pattern
  </parse>
</filter>

<filter kubernetes.var.log.containers.neutron-server**>
  @type grep
  <exclude>
    key log
    pattern \"password\"\:
  </exclude>
</filter>

<filter kubernetes.var.log.containers.documentation** kubernetes.var.log.containers.arc** kubernetes.var.log.containers.operations** kubernetes.var.log.containers.sentry** kubernetes.var.log.containers.horizon**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{IP:remote_addr} %{NOTSPACE:ident} %{NOTSPACE:auth} \[%{HAPROXYDATE:timestamp}\] "%{WORD:request_method} %{NOTSPACE:request_path} %{NOTSPACE:httpversion}" %{NUMBER:response} %{NUMBER:content_length:integer} \"(?<referer>[^\"]{,255}).*?" "%{GREEDYDATA:user_agent}\"?( )?(%{BASE10NUM:request_time:float})
    custom_pattern_path /fluentd/etc/pattern
  </parse>
</filter>


<filter kubernetes.var.log.containers.kube-system-metal-ingress-nginx-controller**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{IP:remote_addr} %{NOTSPACE:ident} %{NOTSPACE:auth} \[%{HTTPDATE:timestamp}\] "%{WORD:request_method} %{NOTSPACE:request_path} %{NOTSPACE:httpversion}" %{NUMBER:response} %{NUMBER:content_length:integer} "(?<referer>[^\"]{,255}).*?" "%{DATA:user_agent}" %{NUMBER:request_length:integer} %{BASE10NUM:request_time:float}( \[%{NOTSPACE:service}\])? ?(\[\])? %{IP:upstream_addr}\:%{NUMBER:upstream_port} %{NUMBER:upstream_response_length:integer} %{BASE10NUM:upstream_response_time:float} %{NOTSPACE:upstream_status}
    custom_pattern_path /fluentd/etc/pattern
  </parse>
</filter>

{{- if .Values.metis.enabled }}
<filter kubernetes.var.log.containers.kube-system-metal-ingress-nginx-controller**>
  @type mysql_enrich
  @log_level info
  host {{.Values.metis.host}}
  port {{.Values.metis.port}}
  database {{.Values.metis.db}}
  username "#{ENV['METIS_USER']}"
  password "#{ENV['METIS_PASSWORD']}"
  sql select ip_address, floating_ip_id, project, project_id, domain, domain_id, network, network_id, subnet, subnet_id, subnetpool, subnetpool_id, router, router_id, port_id, instance_id, owner from openstack_ips;
  sql_key ip_address
  record_key remote_addr
  columns project, project_id, domain, domain_id, port_id, network, network_id, subnet, subnet_id, subnetpool, subnetpool_id, router, router_id, instance_id, owner
  record_mapping project_id:cc_project_id,project:cc_project,port_id:cc_port_id,domain:cc_domain,domain_id:cc_domain_id,network:cc_network,network_id:cc_network_id,subnet:cc_subnet,subnet_id:cc_subnet_id,subnetpool:cc_subnetpool,subnetpool_id:cc_subnetpool_id,router:cc_router,router_id:cc_router_id,instance_id:cc_instance_id,owner:cc_owner
  refresh_interval 3600
</filter>
{{- end }}

<filter kubernetes.var.log.containers.elektra**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    <grok>
      pattern \[%{NOTSPACE:request}\] %{WORD} %{WORD:method} \"%{NOTSPACE:url} %{WORD} %{IP:ip} %{WORD} %{TIMESTAMP_ISO8601:timestamp}
    </grok>
    <grok>
      pattern \[%{NOTSPACE:request}\] %{WORD} %{NUMBER:response}
    </grok>
    <grok>
      pattern \[%{NOTSPACE:request}\]
    </grok>
  </parse>
</filter>

<filter kubernetes.var.log.containers.concourse-web**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{TIMESTAMP_ISO8601:timestamp} \| %{NOTSPACE:loglevel} \| %{NOTSPACE:process}
  </parse>
</filter>

<filter kubernetes.var.log.containers.{{.Values.global.region}}-px**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{WORD:process}:%{SPACE}%{WORD}%{SPACE}%{NOTSPACE:device}%{SPACE}%{GREEDYDATA:error_message}\(%{NUMBER}\),%{SPACE}action:%{SPACE}%{WORD:action}
  </parse>
</filter>

<filter kubernetes.var.log.containers.mysql**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{TIMESTAMP_ISO8601:timestamp} \+0000 %{WORD:process}
  </parse>
</filter>

<filter kubernetes.var.log.containers.ad-healthcheck** kubernetes.var.log.containers.elektra-postgresql** kubernetes.var.log.containers.trident** kubernetes.var.log.containers.prometheus-frontend** kubernetes.var.log.containers.blackbox**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    <grok>
      pattern time=\"%{TIMESTAMP_ISO8601:timestamp}\" level=%{NOTSPACE:loglevel}
    </grok>
    <grok>
      pattern %{TIMESTAMP_ISO8601:timestamp}.%{NUMBER} \| %{WORD:loglevel} \| %{WORD:process}
    </grok>
  </parse>
</filter>

<filter kubernetes.var.log.containers.content-repo**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{DATE_EU:timestamp} %{TIME:timestamp} %{NOTSPACE:loglevel}\:
  </parse>
</filter>

<filter kubernetes.var.log.containers.snmp-exporter**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern ts=%{TIMESTAMP_ISO8601:timestamp} caller=%{NOTSPACE} level=%{NOTSPACE:loglevel} auth=%{NOTSPACE:snmp_auth} target=%{IP:snmp_ip} module=%{NOTSPACE:snmp_module} msg=\"%{GREEDYDATA:snmp_error}\" err=\"%{GREEDYDATA}: %{GREEDYDATA:snmp_reason}\"
  </parse>
</filter>

<filter kubernetes.var.log.containers.arc-api**>
  @type record_transformer
  <record>
    process "arc-api"
  </record>
</filter>

<filter kubernetes.var.log.containers.arc-updates-proxy**>
  @type record_transformer
  <record>
    process "arc-proxy"
  </record>
</filter>
{{- if .Values.swift.enabled }}
<filter swift.var.log.containers.swift-proxy**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{SYSLOGTIMESTAMP:date} %{HOSTNAME:host} %{WORD}.%{LOGLEVEL} %{SYSLOGPROG}: %{HOSTNAME:client_ip} %{HOSTNAME:remote_addr} %{NOTSPACE:datetime} %{WORD:request_method} %{SWIFTREQPATH:request_path}(?:%{SWIFTREQPARAM:request_param})? %{NOTSPACE:protocol} %{NUMBER:response} (?<referer>\S{,255})\S*? %{NOTSPACE:user_agent} %{NOTSPACE:auth_token} %{NOTSPACE:bytes_recvd:integer} %{NOTSPACE:bytes_sent:integer} %{NOTSPACE:client_etag} %{NOTSPACE:transaction_id} %{NOTSPACE:headers} %{BASE10NUM:request_time:float} %{NOTSPACE:source} %{NOTSPACE:log_info} %{BASE10NUM:request_start_time:float} %{BASE10NUM:request_end_time:float} %{NOTSPACE:policy_index}
    custom_pattern_path /fluentd/etc/pattern
  </parse>
</filter>

<filter swift.var.log.containers.swift-proxy**>
  @type record_transformer
  <record>
    remove_keys auth_token
  </record>
</filter>

<filter swift.var.log.containers.swift-servers**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{SYSLOGTIMESTAMP:date} %{HOSTNAME:host} %{WORD}.%{LOGLEVEL} %{SYSLOGPROG}: %{HOSTNAME:remote_addr} - - \[%{NOTSPACE:datetime} %{NOTSPACE:tz}\] \"%{WORD:request_method} (?<request_path>[^\"\s]{,255}).*?\" %{NUMBER:response} %{NOTSPACE:content_length:integer} \"(?<referer>[^\"]{,255}).*?\" \"%{NOTSPACE:transaction_id}\" \"%{DATA:user_agent}\" %{BASE10NUM:request_time:float} \"%{NOTSPACE:additional_info}\" %{NOTSPACE:server_pid} %{NOTSPACE:policy_index}
  </parse>
</filter>
{{- else }}
<filter kubernetes.var.log.containers.swift-proxy**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{SYSLOGTIMESTAMP:date} %{HOSTNAME:host} %{WORD}.%{LOGLEVEL} %{SYSLOGPROG}: %{HOSTNAME:client_ip} %{HOSTNAME:remote_addr} %{NOTSPACE:datetime} %{WORD:request_method} %{SWIFTREQPATH:request_path}(?:%{SWIFTREQPARAM:request_param})? %{NOTSPACE:protocol} %{NUMBER:response} (?<referer>\S{,255})\S*? %{NOTSPACE:user_agent} %{NOTSPACE:auth_token} %{NOTSPACE:bytes_recvd:integer} %{NOTSPACE:bytes_sent:integer} %{NOTSPACE:client_etag} %{NOTSPACE:transaction_id} %{NOTSPACE:headers} %{BASE10NUM:request_time:float} %{NOTSPACE:source} %{NOTSPACE:log_info} %{BASE10NUM:request_start_time:float} %{BASE10NUM:request_end_time:float} %{NOTSPACE:policy_index}
    custom_pattern_path /fluentd/etc/pattern
  </parse>
</filter>

<filter kubernetes.var.log.containers.swift-proxy**>
  @type record_transformer
  <record>
    remove_keys auth_token
  </record>
</filter>

<filter kubernetes.var.log.containers.swift-servers**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{SYSLOGTIMESTAMP:date} %{HOSTNAME:host} %{WORD}.%{LOGLEVEL} %{SYSLOGPROG}: %{HOSTNAME:remote_addr} - - \[%{NOTSPACE:datetime} %{NOTSPACE:tz}\] \"%{WORD:request_method} (?<request_path>[^\"\s]{,255}).*?\" %{NUMBER:response} %{NOTSPACE:content_length:integer} \"(?<referer>[^\"]{,255}).*?\" \"%{NOTSPACE:transaction_id}\" \"%{DATA:user_agent}\" %{NOTSPACE:request_time} \"%{NOTSPACE:additional_info}\" %{NOTSPACE:server_pid} %{NOTSPACE:policy_index}
  </parse>
</filter>
{{- end }}

<filter kubernetes.var.log.containers.keystone-api**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{DATE_EU:timestamp} %{TIME:timestamp} %{NUMBER} %{NOTSPACE:loglevel} %{JAVACLASS:component} \[%{NOTSPACE:requestid} %{NOTSPACE:global_request_id} usr %{DATA:usr} prj %{DATA:prj} dom %{DATA:dom} usr-dom %{DATA:usr_domain} prj-dom %{DATA}\] %{DATA:action} %{METHOD:method} %{URIPATH:pri_path}, %{LOWER:action} (?:b\')?%{NOTSPACE:user}(?:\') (?:b\')?%{WORD:domain}(?:\') %{GREEDYDATA:action}
    custom_pattern_path /fluentd/etc/pattern
    grok_failure_key grok_failure
  </parse>
</filter>

<filter kubernetes.var.log.containers.logs-k8s-event-exporter**>
  @type parser
  @id json_parser
  key_name log
  reserve_data true
  inject_key_prefix k8s.
  remove_key_name_field false
  <parse>
    @type json
    time_format %Y-%m-%dT%T.%L%Z
    keep_time_key true
  </parse>
</filter>

<filter kubernetes.var.log.containers.elektra**>
  @type record_transformer
  <record>
    process "elektra"
  </record>
</filter>

<filter kubernetes.var.log.containers.elektra-postgresql**>
  @type record_transformer
  <record>
    process "elektra-postgresql"
  </record>
</filter>

<filter kubernetes.var.log.containers.content-repo**>
  @type record_transformer
  <record>
    process "swift-http-import"
  </record>
</filter>

<filter kubernetes.var.log.containers.designate-api**>
  @type record_transformer
  <record>
    process "designate-api"
  </record>
</filter>

<filter kubernetes.var.log.containers.nginx**>
  @type record_transformer
  <record>
    process "nginx"
  </record>
</filter>

<filter kubernetes.var.log.containers.neutron-server**>
  @type record_transformer
  <record>
    process "neutron-server"
  </record>
</filter>

<filter kubernetes.var.log.containers.nova-scheduler**>
  @type record_transformer
  <record>
    process "nova-scheduler"
  </record>
</filter>

<filter kubernetes.var.log.containers.nova-compute**>
  @type record_transformer
  <record>
    process "nova-compute"
  </record>
</filter>

<filter kubernetes.var.log.containers.concourse-web**>
  @type record_transformer
  <record>
    process "concourse-web"
  </record>
</filter>

<filter kubernetes.var.log.containers.lyra-api**>
  @type record_transformer
  <record>
    process "lyra-api"
  </record>
</filter>

<filter kubernetes.var.log.containers.lyra-worker**>
  @type record_transformer
  <record>
    process "lyra-worker"
  </record>
</filter>

<filter kubernetes.var.log.containers.vcenter-operator**>
  @type record_transformer
  <record>
    process "vcenter-operator"
  </record>
</filter>

<filter kubernetes.var.log.containers.blackbox-datapath**>
  @type record_transformer
  <record>
    process "blackbox-datapath"
  </record>
</filter>

<filter kubernetes.**>
  @type record_modifier
    remove_keys message,stream
</filter>
{{- if .Values.swift.enabled }}
<filter swift.**>
  @type record_modifier
    remove_keys message,stream
</filter>
{{- end }}

{{- if not .Values.logs.unbound.enabled }}
<match kubernetes.var.log.containers.unbound**>
  @type null
</match>
{{- end }}

<match kubernetes.var.log.containers.cfm**>
  @type null
</match>

<match kubernetes.var.log.containers.fluent**>
  @type null
</match>

<match kubernetes.var.log.containers.es-query-exporter**>
  @type null
</match>

<filter kubernetes.**>
  @type flatten_hash
  @id flatten_hash
  separator _
  flatten_array false
</filter>

{{- if .Values.swift.enabled }}
<filter swift.**>
  @type flatten_hash
  @id flatten_swift_hash
  separator _
  flatten_array false
</filter>
{{- end }}

<filter kubernetes.**>
  @type rename_key
  @id rename_key
  rename_rule1 kubernetes_labels_app kubernetes_labels_app_name
</filter>

{{- if .Values.swift.enabled }}
<filter swift.**>
  @type rename_key
  @id rename_swift_key
  rename_rule1 kubernetes_labels_app kubernetes_labels_app_name
</filter>
{{- end }}

{{- if .Values.swift.enabled }}
<match swift.**>
  @type copy
  @id copy_swift
  <store>
    @type opensearch
    @id opensearch_swift
    logstash_prefix logstash-swift
    logstash_format true
    template_name logstash-swift
    template_file /fluentd/etc/logstashswift.json
    template_overwrite false
    hosts {{.Values.global.opensearch.host}}
    scheme https
    port {{.Values.global.opensearch.port}}
    user "#{ENV['USER']}"
    password "#{ENV['PASSWORD']}"
    log_os_400_reason true
    ssl_verify true
    ssl_version TLSv1_2
    time_as_integer false
    @log_level info
    slow_flush_log_threshold 50.0
    request_timeout 60s
    include_tag_key true
    resurrect_after 120
    reconnect_on_error true
    reload_connections false
    reload_on_failure false
    suppress_type_name true
    <buffer>
      total_limit_size 256MB
      flush_at_shutdown true
      flush_thread_interval 5
      overflow_action block
      retry_forever true
      retry_wait 2s
      flush_thread_count 2
      flush_interval 2s
    </buffer>
  </store>
  <store>
    @type prometheus
    @id prometheus_swift
    <metric>
      name fluentd_output_status_num_records_total
      type counter
      desc The total number of outgoing records
      <labels>
        cluster_type metal
        nodename "#{ENV['K8S_NODE_NAME']}"
        hostname ${hostname}
        tag ${tag}
        source swift
      </labels>
    </metric>
  </store>
 </match>
{{- end }}


# count number of outgoing records per tag
<match kubernetes.**>
  @type copy
  @id copy_kubernetes
  <store>
  {{- if .Values.opensearch.datastream.enabled }}
    @type opensearch_data_stream
    data_stream_name logs
  {{- else }}
    @type opensearch
    @id opensearch_kubernetes
    logstash_prefix {{.Values.opensearch.indexname}}
    logstash_format true
    template_name {{.Values.opensearch.indexname}}
    template_file /fluentd/etc/{{.Values.opensearch.indexname}}.json
    template_overwrite false
  {{- end }}
    hosts {{.Values.global.opensearch.host}}
    scheme https
    port {{.Values.global.opensearch.port}}
    user "#{ENV['USER']}"
    password "#{ENV['PASSWORD']}"
    log_os_400_reason true
    ssl_verify true
    ssl_version TLSv1_2
    time_as_integer false
    @log_level info
    slow_flush_log_threshold 50.0
    request_timeout 60s
    include_tag_key true
    resurrect_after 120
    reconnect_on_error true
    reload_connections false
    reload_on_failure false
    suppress_type_name true
    <buffer>
      total_limit_size 256MB
      flush_at_shutdown true
      flush_thread_interval 5
      overflow_action block
      retry_forever true
      retry_wait 2s
      flush_thread_count 2
      flush_interval 2s
    </buffer>
  </store>
  <store>
    @type prometheus
    @id prometheus_kubernetes
    <metric>
      name fluentd_output_status_num_records_total
      type counter
      desc The total number of outgoing records
      <labels>
        cluster_type metal
        nodename "#{ENV['K8S_NODE_NAME']}"
        hostname ${hostname}
        tag ${tag}
        source all
      </labels>
    </metric>
  </store>
 </match>
