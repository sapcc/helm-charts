<source>
  @type syslog
  bind {{default "0.0.0.0" .Values.fluent_vcenter.vcenter_logs_in_ip}}
  port {{.Values.fluent_vcenter.vcenter_logs_in_port}}
  protocol_type {{.Values.fluent_vcenter.vcenter_logs_in_proto}}
  tag vcenter
  message_format auto
  with_priority true
</source>

<source>
  @type udp
  tag vcenter
  format /^(?<time>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*) (?:\[(?<pid1>[0-9]+)\])?(?:[^\:]*\:)? *(?<message>.*)$/
  port {{.Values.fluent_vcenter.esx_logs_in_port}}
  bind {{default "0.0.0.0" .Values.fluent_vcenter.esx_logs_in_ip}}
</source>

<source>
  @type prometheus
  bind {{default "0.0.0.0" .Values.fluent_vcenter.prometheus_ip}}
  port {{.Values.fluent_vcenter.prometheus_port}}
</source>

<match vcenter.**>
  @type copy
  <store>
    @type elasticsearch
    host es-client
    port 9200
    user {{.Values.elk_elasticsearch_admin_user}}
    password {{.Values.elk_elasticsearch_admin_password}}
    index_name vcenter
    type_name fluentd
    logstash_prefix vcenter
    logstash_format true
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
  </store>
  <store>
    @type rewrite_tag_filter
    <rule>
      key message
      pattern AdapterServer\scaught\sexception:\soptional\svalue\snot\sset
      tag SR17595168510.${tag}
    </rule>
    <rule>
      key message
      pattern Error\sgetting\sdvport\slist\sfor.+Status\(bad0014\)=\sOut\sof\smemory
      tag SR17629377811.${tag}
    </rule>
    <rule>
      key message
      pattern ERROR.+networkSystem.+vim.host.NetworkSystem.invokeHostTransactionCall:\svmodl.fault.
      tag OOM.${tag}
    </rule>
  </store>
</match>

<match SR17595168510.**>
  @type prometheus
  <metric>
    name vcenter_SR17595168510
    type counter
    desc Found error pertaining to SR17595168510
    <labels>
      tag ${tag}
      host ${host}
    </labels>
  </metric>
</match>

<match SR17629377811.**>
  @type prometheus
  <metric>
    name vcenter_SR17629377811
    type counter
    desc Found error pertaining to SR17629377811
    <labels>
      tag ${tag} 
      host ${host}
    </labels>
  </metric>
</match>

<match OOM.**>
  @type prometheus
  <metric>
    name vcenter_dvswitch_out_of_memory
    type counter
    desc Found Error that indicates long timeout on dvs calls
    <labels>
      tag ${tag} 
      host ${host}
    </labels>
  </metric>
</match>
