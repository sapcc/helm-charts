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
  log_level info
</system>

# All the auto-generated files should use the tag "file.<filename>".
<source>
  @type tail
  path /var/log/containers/*.log
  pos_file /var/log/es-containers.log.pos
  time_format %Y-%m-%dT%H:%M:%S.%N
  tag kubernetes.*
  format json
  read_from_head true
  keep_time_key true
</source>

<filter kubernetes.**>
  @type kubernetes_metadata
  kubernetes_url https://KUBERNETES_SERVICE_HOST
  bearer_token_file /var/run/secrets/kubernetes.io/serviceaccount/token
  ca_file /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  include_namespace_id true
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

<filter kubernetes.var.log.containers.manila** kubernetes.var.log.containers.ironic** kubernetes.var.log.containers.cinder**  kubernetes.var.log.containers.nova** kubernetes.var.log.containers.glance** kubernetes.var.log.containers.keystone** kubernetes.var.log.containers.designate** kubernetes.var.log.containers.neutron-server** kubernetes.var.log.containers.neutron** kubernetes.var.log.containers.barbican** kubernetes.var.log.containers.ceilometer-central**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{TIMESTAMP_ISO8601:timestamp}.%{NUMBER} %{NUMBER:pid} %{WORD:loglevel} %{NOTSPACE:process} (\[)?(req-)?(%{REQUESTID:requestid})
    custom_pattern_path /fluent-etc/pattern
  </parse>
</filter>


<filter kubernetes.var.log.containers.neutron-server**>
  @type grep
  <exclude>
    key log
    pattern \"password\"\:
  </exclude>
</filter>

<filter kubernetes.var.log.containers.unbound**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern \[%{DATA:timestamp}\] %{NOTSPACE:process} %{WORD:loglevel}
  </parse>
</filter>


<filter kubernetes.var.log.containers.documentation** kubernetes.var.log.containers.arc** kubernetes.var.log.containers.operations** kubernetes.var.log.containers.sentry** kubernetes.var.log.containers.nginx** kubernetes.var.log.containers.horizon**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
    grok_pattern %{IP:remote_addr} %{NOTSPACE:ident} %{NOTSPACE:auth} \[%{HAPROXYDATE:timestamp}\] "%{WORD:request_method} %{NOTSPACE:request_path} %{NOTSPACE:httpversion}" %{NUMBER:response} %{NUMBER:content_length} \"(?<referer>[^\"]{,255}).*?" "%{GREEDYDATA:user_agent}\"?( )?(%{NOTSPACE:request_time})
    custom_pattern_path /fluent-etc/pattern
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

<filter kubernetes.var.log.containers.ingress-controller**>
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type grok
      grok_pattern %{IP:remote_addr} - \[%{GREEDYDATA:proxy_add_x_forwarded_for}\] - %{NOTSPACE:auth} \[%{HAPROXYDATE:timestamp}\] "%{WORD:request_method} %{NOTSPACE:request_path} %{NOTSPACE:httpversion}" %{NUMBER:response} %{NUMBER:content_length} "(?<referer>[^\"]{,255}).*?" "%{DATA:user_agent}" %{NUMBER:request_length} %{NUMBER:request_time}( \[%{NOTSPACE:service}\])? %{IP:upstream_addr}\:%{NUMBER:upstream_port} %{NUMBER:upstream_response_length} %{NOTSPACE:upstream_response_time} %{NOTSPACE:upstream_status}
      custom_pattern_path /fluent-etc/pattern
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
    grok_pattern %{COMBINEDAPACHELOG}
   time_format "%d/%b/%Y:%H:%M:%S %z"
    custom_pattern_path /fluent-etc/pattern
  </parse>
</filter>

<filter kubernetes.var.log.containers.swift-proxy-ksr**>
  @type record_transformer
  <record>
    process "swift-proxy-ksr"
  </record>
</filter>

<filter kubernetes.var.log.containers.swift-proxy-cluster-3**>
  @type record_transformer
  <record>
    process "swift-proxy-cluster-3"
  </record>
</filter>

<filter kubernetes.var.log.containers.swift-object-expirer**>
@type record_transformer
<record>
  process "swift-object-expirer"
</record>
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

<filter kubernetes.var.log.containers.unbound1**>
  @type record_transformer
  <record>
    process "unbound1"
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

#<filter kubernetes.var.log.containers.postgres**>
#  @type record_transformer
#  enable_ruby
#  <record>
#    loglevel ${record["message".upcase]}
#  </record>
#</filter>

#<filter kubernetes.var.log.containers.arc**>
#  @type record_transformer
#  enable_ruby
#  <record>
#    loglevel ${record["message".upcase]}
#  </record>
#</filter>

#<filter kubernetes.var.log.containers.prometheus-frontend**>
#  @type record_transformer
#  enable_ruby
#  <record>
#    loglevel ${record["message".upcase]}
#  </record>
#</filter>

#<filter kubernetes.var.log.containers.blackbox**>
#  @type record_transformer
#  enable_ruby
#  <record>
#    loglevel ${record["message".upcase]}
#  </record>
#</filter>

#<filter kubernetes.var.log.containers.elk-fluent**>
#  @type record_transformer
#  enable_ruby
#  <record>
#    loglevel ${record["message".upcase]}
#  </record>
#</filter>

<filter kubernetes.**>
  @type record_modifier
    remove_keys message,stream
</filter>

<match **>
   @type elasticsearch
   host {{.Values.elk_elasticsearch_endpoint_host_internal}}
   port {{.Values.elk_elasticsearch_port_internal}}
   user {{.Values.elk_elasticsearch_data_user}}
   password {{.Values.elk_elasticsearch_data_password}}
   time_as_integer false
   @log_level info
   buffer_type "memory"
   buffer_chunk_limit 96m
   buffer_queue_limit 256
   buffer_queue_full_action exception
   slow_flush_log_threshold 40.0
   flush_interval 3s
   retry_wait 2s
   include_tag_key true
   logstash_format true
   max_retry_wait 10s
   disable_retry_limit
   request_timeout 60s
   reload_connections true
   reload_on_failure true
   resurrect_after 120
   reconnect_on_error true
   num_threads 8
 </match>
