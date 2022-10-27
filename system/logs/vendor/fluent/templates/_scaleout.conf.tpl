<filter kubernetes.var.log.containers.es**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern \[%{TIMESTAMP_ISO8601:timestamp}\]\[%{WORD:loglevel}
    grok_pattern %{TIMESTAMP_ISO8601:timestamp} \| %{NOTSPACE:loglevel}
  </parse>
</filter>

<filter kubernetes.var.log.containers.elk-k8s-event-exporter**>
  @type parser
  @id json_parser
  key_name log
  reserve_data true
  inject_key_prefix k8s.
  remove_key_name_field true
  <parse>
    @type json
    time_format %Y-%m-%dT%T.%L%Z
    keep_time_key true
  </parse>
</filter>


<filter kubernetes.var.log.containers.elk-fluent**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{TIMESTAMP_ISO8601:timestamp} \+0000 \[%{WORD:loglevel}
  </parse>
</filter>

<filter kubernetes.var.log.containers.elk-wall-e**>
  @type record_transformer
  <record>
    process "elk-wall-e"
  </record>
</filter>

<filter kubernetes.var.log.containers.elk-fluent**>
  @type record_transformer
  <record>
    process "elk-fluent"
  </record>
</filter>

<filter kubernetes.var.log.containers.es-client**>
  @type record_transformer
  <record>
    process "es-client"
  </record>
</filter>

<filter kubernetes.var.log.containers.es-master**>
  @type record_transformer
  <record>
    process "es-master"
  </record>
</filter>

<filter kubernetes.var.log.containers.es-data**>
  @type record_transformer
  <record>
    process "es-data"
  </record>
</filter>

<filter kubernetes.**>
  @type record_modifier
    remove_keys message,stream
</filter>

<match kubernetes.var.log.containers.fluent**>
  @type null
</match>

<match kubernetes.var.log.containers.es-query-exporter**>
  @type null
</match>

<match kubernetes.var.log.containers.logstash**>
  @type null
</match>
#<filter kubernetes.var.log.containers.ingress-controller**>
#  @type parser
#  key_name log
#  reserve_data true
#  <parse>
#    @type grok
#    grok_pattern %{IP:remote_addr} - \[%{GREEDYDATA:proxy_add_x_forwarded_for}\] - %{NOTSPACE:auth} \[%{HAPROXYDATE:timestamp}\] "%{WORD:request_method} %{NOTSPACE:request_path} %{NOTSPACE:httpversion}" %{NUMBER:response} %{NUMBER:content_length} "(?<referer>[^\"]{,255}).*?" "%{DATA:user_agent}" %{NUMBER:request_length} %{NUMBER:request_time}( \[%{NOTSPACE:service}\])? %{IP:upstream_addr}\:%{NUMBER:upstream_port} %{NUMBER:upstream_response_length} %{NOTSPACE:upstream_response_time} %{NOTSPACE:upstream_status}
#  </parse>
#</filter>

<filter kubernetes.var.log.containers.kube-system-nginx-ingress-controller**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{IPV4:remote_addr} %{GREEDYDATA}
    custom_pattern_path /fluentd/etc/pattern
  </parse>
</filter>

{{- if .Values.metis.enabled }}
<filter kubernetes.var.log.containers.kube-system-nginx-ingress-controller**>
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
    @type elasticsearch
    host {{.Values.endpoint_host_internal}}
    port {{.Values.http_port}}
    user {{.Values.global.elk_elasticsearch_data_user}}
    password {{.Values.global.elk_elasticsearch_data_password}}
    ssl_verify false
    ssl_version TLSv1_2
    logstash_prefix {{.Values.indexname}}
    logstash_format true
    template_name {{.Values.indexname}}
    template_file /fluentd/etc/{{.Values.indexname}}.json
    template_overwrite false
    time_as_integer false
    type_name _doc
    @log_level info
    slow_flush_log_threshold 50.0
    request_timeout 60s
    include_tag_key true
    resurrect_after 120
    reconnect_on_error true
    <buffer>
      total_limit_size 256MB
      flush_at_shutdown true
      flush_thread_interval 5
      overflow_action block
      retry_forever true
      retry_wait 2s
      flush_thread_count 2
      flush_interval 1s
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
        fluent_container $.kubernetes.pod_name
        nodename "#{ENV['K8S_NODE_NAME']}"
        container $.kubernetes.container_name
      </labels>
    </metric>
  </store>
 </match>
