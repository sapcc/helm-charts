# This Fluentd configuration file enables the collection of log files
# that can be specified at the time of its creation in an environment
# variable, assuming that the config_generator.sh script runs to generate
# a configuration file for each log file to collect.
# Logs collected will be sent to the cluster's Elasticsearch service.
#
# Currently the collector uses a text format rather than allowing the user
# to specify how to parse each file.

# Pick up all the auto-generated input config files, one for each file
# specified in the FILES_TO_COLLECT environment variable.
@include files/*

<system>
  log_level warn
</system>

<label @FLUENT_LOG>
  <match fluent.*>
    @type stdout
  </match>
</label>

# All the auto-generated files should use the tag "file.<filename>".
<source>
  @type tail
  path /var/log/containers/*.log
  exclude_path /var/log/containers/fluentd*
  pos_file /var/log/es-containers.log.pos
  time_format %Y-%m-%dT%H:%M:%S.%N
  tag kubernetes.*
  format json
  keep_time_key true
</source>

<match fluent.**>
  @type null
</match>

# prometheus monitoring config

@include /fluent-bin/prometheus.conf

<filter kubernetes.**>
  @type kubernetes_metadata
  kubernetes_url https://KUBERNETES_SERVICE_HOST
  bearer_token_file /var/run/secrets/kubernetes.io/serviceaccount/token
  ca_file /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  use_journal 'false'
  container_name_to_kubernetes_regexp '^(?<name_prefix>[^_]+)_(?<container_name>[^\._]+)(\.(?<container_hash>[^_]+))?_(?<pod_name>[^_]+)_(?<namespace>[^_]+)_[^_]+_[^_]+$'
</filter>

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

<filter kubernetes.var.log.containers.ironic** kubernetes.var.log.containers.cinder**  kubernetes.var.log.containers.nova** kubernetes.var.log.containers.glance** kubernetes.var.log.containers.designate** kubernetes.var.log.containers.neutron-server** kubernetes.var.log.containers.neutron** kubernetes.var.log.containers.barbican** kubernetes.var.log.containers.ceilometer-central**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{TIMESTAMP_ISO8601:timestamp}.%{NUMBER} %{NUMBER:pid} %{WORD:loglevel} %{NOTSPACE:logger} (\[)?(req-)?(%{REQUESTID:requestid})
    custom_pattern_path /fluent-bin/pattern
  </parse>
</filter>

<filter kubernetes.var.log.containers.manila-api** kubernetes.var.log.containers.manila-scheduler** kubernetes.var.log.containers.manila-share-netapp**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern (%{TIMESTAMP_ISO8601:logtime}|)( )?%{TIMESTAMP_ISO8601:timestamp}.%{NOTSPACE} %{NUMBER:pid} %{NOTSPACE:log_level} %{NOTSPACE:program} (\[?)%{NOTSPACE:request_id} %{NOTSPACE:user_id} %{NOTSPACE:project_id} %{NOTSPACE:domain_id} %{NOTSPACE:id1} %{REQUESTID:id2}(\]?) %{GREEDYDATA:log_request}
    custom_pattern_path /fluent-bin/pattern
  </parse>
</filter>

<filter kubernetes.var.log.containers.neutron-server**>
  @type grep
  <exclude>
    key log
    pattern \"password\"\:
  </exclude>
</filter>

<filter kubernetes.var.log.containers.documentation** kubernetes.var.log.containers.arc** kubernetes.var.log.containers.operations** kubernetes.var.log.containers.sentry** kubernetes.var.log.containers.nginx** kubernetes.var.log.containers.horizon**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{IP:remote_addr} %{NOTSPACE:ident} %{NOTSPACE:auth} \[%{HAPROXYDATE:timestamp}\] "%{WORD:request_method} %{NOTSPACE:request_path} %{NOTSPACE:httpversion}" %{NUMBER:response} %{NUMBER:content_length} \"(?<referer>[^\"]{,255}).*?" "%{GREEDYDATA:user_agent}\"?( )?(%{NOTSPACE:request_time})
    custom_pattern_path /fluent-bin/pattern
  </parse>
</filter>

<filter kubernetes.var.log.containers.elektra**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern \[%{NOTSPACE:request}\] %{WORD} %{WORD:method} \"%{NOTSPACE:url} %{WORD} %{IP:ip} %{WORD} %{TIMESTAMP_ISO8601:timestamp}
    grok_pattern \[%{NOTSPACE:request}\] %{WORD} %{NUMBER:response}
    grok_pattern \[%{NOTSPACE:request}\]
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

<filter kubernetes.var.log.containers.mysql**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{TIMESTAMP_ISO8601:timestamp} \+0000 %{WORD:process}
  </parse>
</filter>

<filter kubernetes.var.log.containers.postgres** kubernetes.var.log.containers.ad-healthcheck** kubernetes.var.log.containers.elektra-postgresql** kubernetes.var.log.containers.trident** kubernetes.var.log.containers.prometheus-frontend** kubernetes.var.log.containers.blackbox**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern time=\"%{TIMESTAMP_ISO8601:timestamp}\" level=%{NOTSPACE:loglevel}
    grok_pattern %{TIMESTAMP_ISO8601:timestamp}.%{NUMBER} \| %{WORD:loglevel} \| %{WORD:process}
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
    grok_pattern level=%{NOTSPACE:loglevel} ts=%{TIMESTAMP_ISO8601:timestamp} caller=%{NOTSPACE} module=%{NOTSPACE:snmp_module} target=%{IP:ip} msg=\"%{GREEDYDATA:snmp_error}\" err=\"%{GREEDYDATA:snmp_msg}\"
  </parse>
</filter>

<filter kubernetes.var.log.containers.ingress-controller**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{IP:remote_addr} - \[%{GREEDYDATA:proxy_add_x_forwarded_for}\] - %{NOTSPACE:auth} \[%{HAPROXYDATE:timestamp}\] "%{WORD:request_method} %{NOTSPACE:request_path} %{NOTSPACE:httpversion}" %{NUMBER:response} %{NUMBER:content_length} "(?<referer>[^\"]{,255}).*?" "%{DATA:user_agent}" %{NUMBER:request_length} %{NUMBER:request_time}( \[%{NOTSPACE:service}\])? %{IP:upstream_addr}\:%{NUMBER:upstream_port} %{NUMBER:upstream_response_length} %{NOTSPACE:upstream_response_time} %{NOTSPACE:upstream_status}
    custom_pattern_path /fluent-bin/pattern
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

<filter kubernetes.var.log.containers.swift-proxy**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{SYSLOGTIMESTAMP:date} %{HOSTNAME:host} %{WORD}.%{LOGLEVEL} %{SYSLOGPROG}: %{HOSTNAME:client_ip} %{HOSTNAME:remote_addr} %{NOTSPACE:datetime} %{WORD:request_method} %{SWIFTREQPATH:request_path}(?:%{SWIFTREQPARAM:request_param})? %{NOTSPACE:protocol} %{NUMBER:response} (?<referer>\S{,255})\S*? %{NOTSPACE:user_agent} %{NOTSPACE:auth_token} %{NOTSPACE:bytes_recvd} %{NOTSPACE:bytes_sent} %{NOTSPACE:client_etag} %{NOTSPACE:transaction_id} %{NOTSPACE:headers} %{NOTSPACE:request_time} %{NOTSPACE:source} %{NOTSPACE:log_info} %{NUMBER:request_start_time} %{NUMBER:request_end_time} %{NOTSPACE:policy_index}
    custom_pattern_path /fluent-bin/pattern
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
    grok_pattern %{SYSLOGTIMESTAMP:date} %{HOSTNAME:host} %{WORD}.%{LOGLEVEL} %{SYSLOGPROG}: %{HOSTNAME:remote_addr} - - \[%{NOTSPACE:datetime} %{NOTSPACE:tz}\] \"%{WORD:request_method} (?<request_path>[^\"\s]{,255}).*?\" %{NUMBER:response} %{NOTSPACE:content_length} \"(?<referer>[^\"]{,255}).*?\" \"%{NOTSPACE:transaction_id}\" \"%{DATA:user_agent}\" %{NOTSPACE:request_time} \"%{NOTSPACE:additional_info}\" %{NOTSPACE:server_pid} %{NOTSPACE:policy_index}
  </parse>
</filter>

<filter kubernetes.var.log.containers.keystone-api**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{DATE_EU:timestamp} %{TIME:timestamp} %{NUMBER} %{NOTSPACE:loglevel} %{JAVACLASS:component} \[%{NOTSPACE:requestid} usr %{DATA:usr} prj %{DATA:prj} dom %{DATA:dom} usr-dom %{DATA:usr_domain} prj-dom %{DATA}\] %{GREEDYDATA:action} %{METHOD:method} %{URIPATH:pri_path} %{LOWER:action} %{NOTSPACE:user} %{WORD:domain} %{GREEDYDATA:action}
    custom_pattern_path /fluent-bin/pattern
    grok_failure_key grok_failure
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

<filter kubernetes.var.log.containers.ingress-controller**>
  @type record_transformer
  <record>
    process "ingress-controller"
  </record>
</filter>

<filter kubernetes.var.log.containers.postgres-keystone**>
  @type record_transformer
  <record>
    process "postgres-keystone"
  </record>
</filter>

<filter kubernetes.var.log.containers.postgres-glance**>
  @type record_transformer
  <record>
    process "postgres-glance"
  </record>
</filter>

<filter kubernetes.var.log.containers.postgres-neutron**>
  @type record_transformer
  <record>
    process "postgres-neutron"
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

<filter kubernetes.var.log.containers.postgres-nova**>
  @type record_transformer
  <record>
    process "postgres-nova"
  </record>
</filter>

<filter kubernetes.var.log.containers.postgres-barbican**>
  @type record_transformer
  <record>
    process "postgres-barbican"
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

<filter kubernetes.var.log.containers.arc-postgresql**>
  @type record_transformer
  <record>
    process "arc-postgresql"
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

<filter kubernetes.var.log.containers.elk-wall-e**>
  @type record_transformer
  <record>
    process "elk-wall-e"
  </record>
</filter>

<filter kubernetes.var.log.containers.concourse-postgresql**>
  @type record_transformer
  <record>
    process "concourse-postgresql"
  </record>
</filter>

<filter kubernetes.var.log.containers.elk-fluent**>
  @type record_transformer
  <record>
    process "elk-fluent"
  </record>
</filter>


<filter kubernetes.var.log.containers.blackbox-datapath**>
  @type record_transformer
  <record>
    process "blackbox-datapath"
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

<match kubernetes.var.log.containers.unbound**>
  @type null
</match>

<match kubernetes.var.log.containers.cfm**>
  @type null
</match>

<match kubernetes.var.log.containers.fluent**>
  @type null
</match>

<match kubernetes.var.log.containers.es-query-exporter**>
  @type null
</match>

<match kubernetes.var.log.containers.logstash**>
  @type null
</match>

{{- if .Values.forwarding.keystone.enabled }}
<match kubernetes.var.log.containers.keystone-api**>
  @type copy
  <store>
    @type http
    endpoint_url "https://{{.Values.forwarding.keystone.host}}"
    cacert_file "/etc/ssl/certs/ca-certificates.crt"
    http_method post
    serializer json
    raise_on_error true
  </store>
  <store>
    @type elasticsearch_dynamic
    host {{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.cluster_region}}.{{.Values.global.domain}}
    port {{.Values.global.elk_elasticsearch_ssl_port}}
    user {{.Values.global.elk_elasticsearch_data_user}}
    password {{.Values.global.elk_elasticsearch_data_password}}
    scheme https
    ssl_verify false
    ssl_version TLSv1_2
    logstash_format true
    template_name logstash
    template_file /fluent-bin/logstash.json
    template_overwrite true
    time_as_integer false
    type_name _doc
    @log_level info
    slow_flush_log_threshold 50.0
    request_timeout 60s
    include_tag_key true
    resurrect_after 120
    reconnect_on_error true
    <buffer>
      total_limit_size 128MB
      flush_at_shutdown true
      flush_thread_interval 5
      overflow_action block
      retry_forever true
      retry_wait 2s
      flush_thread_count 2
      flush_interval 1s
    </buffer>
  </store>
</match>
{{- end }}

# count number of outgoing records per tag
<match kubernetes.**>
  @type copy
  <store>
    @type elasticsearch_dynamic
    host {{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.cluster_region}}.{{.Values.global.domain}}
    port {{.Values.global.elk_elasticsearch_ssl_port}}
    user {{.Values.global.elk_elasticsearch_data_user}}
    password {{.Values.global.elk_elasticsearch_data_password}}
    scheme https
    ssl_verify false
    ssl_version TLSv1_2
    logstash_format true
    template_name logstash
    template_file /fluent-bin/logstash.json
    template_overwrite true
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
        nodename "#{ENV['K8S_NODE_NAME']}"
        container $.kubernetes.container_name
      </labels>
    </metric>
  </store>
 </match>
