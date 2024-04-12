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

<filter kubernetes.var.log.containers.fluent**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{TIMESTAMP_ISO8601:timestamp} \+0000 \[%{WORD:loglevel}
  </parse>
</filter>

<filter kubernetes.**>
  @type record_modifier
    remove_keys message,stream
</filter>

<match kubernetes.var.log.containers.fluent**>
  @type null
</match>

<match kubernetes.var.log.containers.logstash**>
  @type null
</match>

<filter kubernetes.var.log.containers.kube-system-ingress-nginx-controller**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{IP:remote_addr} %{NOTSPACE:ident} %{NOTSPACE:auth} \[%{HTTPDATE:timestamp}\] "%{WORD:request_method} %{NOTSPACE:request_path} %{NOTSPACE:httpversion}" %{NUMBER:response} %{NUMBER:content_length:integer} "(?<referer>[^\"]{,255}).*?" "%{DATA:user_agent}" %{NUMBER:request_length:integer} %{BASE10NUM:request_time:float}( \[%{NOTSPACE:service}\])? ?(\[\])? %{IP:upstream_addr}\:%{NUMBER:upstream_port} %{NUMBER:upstream_response_length:integer} %{BASE10NUM:upstream_response_time:float} %{NOTSPACE:upstream_status}
  </parse>
</filter>

{{- if .Values.metis.enabled }}
<filter kubernetes.var.log.containers.kube-system-ingress-nginx-controller**>
  @type mysql_enrich
  host {{.Values.metis.host}}.{{.Values.global.region}}.{{.Values.global.tld}}
  port {{.Values.metis.port}}
  database {{.Values.metis.db}}
  username {{.Values.global.metis.user}}
  password {{.Values.global.metis.password}}
  sql select ip_address, floating_ip_id, project, project_id, domain, domain_id, network, network_id, subnet, subnet_id, subnetpool, subnetpool_id, router, router_id, port_id, instance_id, owner from openstack_ips;
  sql_key ip_address
  record_key remote_addr
  columns project, project_id, domain, domain_id, port_id, network, network_id, subnet, subnet_id, subnetpool, subnetpool_id, router, router_id, instance_id, owner
  record_mapping project_id:cc_project_id,project:cc_project,port_id:cc_port_id,domain:cc_domain,domain_id:cc_domain_id,network:cc_network,network_id:cc_network_id,subnet:cc_subnet,subnet_id:cc_subnet_id,subnetpool:cc_subnetpool,subnetpool_id:cc_subnetpool_id,router:cc_router,router_id:cc_router_id,instance_id:cc_instance_id,owner:cc_owner
  refresh_interval 3600
</filter>
{{- end }}

<filter kubernetes.**>
  @type flatten_hash
  @id flatten_hash
  separator _
  flatten_array false
</filter>

<filter kubernetes.**>
  @type rename_key
  @id rename_key
  rename_rule1 kubernetes_labels_app kubernetes_labels_app_name
</filter>

# count number of outgoing records per tag
<match kubernetes.**>
  @type copy
  <store>
  {{- if .Values.opensearch.datastream.enabled }}
    @type opensearch_data_stream
    data_stream_name logs
  {{- else }}
    @type opensearch
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
    ssl_verify false
    ssl_version TLSv1_2
    log_os_400_reason true
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
    <metric>
      name fluentd_output_status_num_records_total
      type counter
      desc The total number of outgoing records
      <labels>
        tag ${tag}
        cluster_type scaleout
        fluent_container $.kubernetes.pod_name
        nodename "#{ENV['K8S_NODE_NAME']}"
        container $.kubernetes.container_name
      </labels>
    </metric>
  </store>
 </match>
