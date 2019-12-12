<source>
  @type {{default "udp" .Values.vcenter_logs_in_proto}}
  tag "vcenter"
  format /^(?<message>.*?)$/
  bind {{default "0.0.0.0" .Values.vcenter_logs_in_ip}}
  port {{.Values.vcenter_logs_in_port}}
</source> 
#<source>
#  @type udp
#  @log_level debug
#  tag "nsxt"
#  format /^(?<message>.*?)$/
#  bind {{default "0.0.0.0" .Values.esx_logs_in_ip}}
#  port 514
#</source>
<source>
  @type syslog
  message_format rfc5424
  port 514
  tag "nsxt"
</source>
<source>
  @type {{default "udp" .Values.esx_logs_in_proto}}
  tag "vcenter"
  format /^(?<message>.*?)$/
  bind {{default "0.0.0.0" .Values.esx_logs_in_ip}}
  port {{.Values.esx_logs_in_port}}
</source>
<filter vcenter.**>
  @type parser
  key_name "message"
  format /(?<message>(^.* (?<host_name>{{default "domain.com" .Values.fqdn_match_string}}).*$)|(^.* (?<node_name>{{default "node" .Values.shortname_match_string}}).*$)|(^.*?$))/
</filter>
<filter vcenter.**>
  @type record_transformer
  enable_ruby yes
  auto_typecast yes
  <record>
    host_name ${record["node_name"] ? record["node_name"] : record["host_name"] ? record["host_name"] : "unknown"}
  </record>
</filter>
<source>
  @type prometheus
  bind "0.0.0.0"
  port 24231
</source>
<match nsxt.**>
  @type rewrite_tag_filter
  <rule>
    key "message"
    pattern /Trim Exception/
    tag "TRIMEXCEPTION.${tag}"
  </rule>
</match>
<match vcenter.**>
  @type rewrite_tag_filter
  <rule>
    key "message"
    pattern AdapterServer\scaught\sexception:\soptional\svalue\snot\sset
    tag "SR17595168510.${tag}"
  </rule>
  <rule>
    key "message"
    pattern Error\sgetting\sdvport\slist\sfor.+Status\(bad0014\)=\sOut\sof\smemory
    tag "SR17629377811.${tag}"
  </rule>
  <rule>
    key "message"
    pattern ERROR.+networkSystem.+vim.host.NetworkSystem.invokeHostTransactionCall:\svmodl.fault.
    tag "DVSTimeout.${tag}"
  </rule>
  <rule>
    key "message"
    pattern ((Unable to Add Port; Status\(bad0006\)= Limit exceeded)|(Failed to get DVS state from vmkernel Status \(bad0014\)= Out of memory))
    tag "DVSOOM.${tag}"
  </rule>
  <rule>
    key "message"
    pattern Failed\sto\s(power on|add disk)\s\'scsi
    tag "vCenterVolumeStuck.${tag}"
  </rule>
  <rule>                                                                                         
    key "host_name"                                                                              
    pattern unknown                                                                              
    tag "unknown.${tag}"                                                                         
  </rule> 
  <rule>
    key "message"
    pattern info
    tag "data.${tag}"
  </rule>
</match>
<match TRIMEXCEPTION.**>
  @type prometheus
  @log_level debug
  <metric>
    name nsxt_trim_exception 
    type counter
    desc Trim Exception seen on in proton logs
    <labels>
      tag ${tag}
      hostname ${host}
    </labels>
  </metric>
</match>
<match SR17595168510.**>
  @type prometheus
  <metric>
    name vcenter_SR17595168510
    type counter
    desc Found error pertaining to SR17595168510
    <labels>
      tag ${tag}
      hostname ${host_name}
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
      host ${host_name}
    </labels>
  </metric>
</match>
<match DVSTimeout.**>
  @type prometheus
  <metric>
    name vcenter_dvswitch_timeout
    type counter
    desc Found Error that indicates long timeout on dvs calls
    <labels>
      tag ${tag}
      host ${host_name}
    </labels>
  </metric>
</match>
<match DVSOOM.**>
  @type prometheus
  <metric>
    name vcenter_dvswitch_out_of_memory
    type counter
    desc Found Error that indicates dvs is out of memory
    <labels>
      tag ${tag}
      host ${host_name}
    </labels>
  </metric>
</match>
<match vCenterVolumeStuck.**>
  @type prometheus
  <metric>
    name vcenter_volume_stuck
    type counter
    desc Found Error that indicates a vCenter volume is vCenterVolumeStuck
    <labels>
      tag ${tag}
      host ${host_name}
    </labels>
  </metric>
</match>
<match data.**>
  @type prometheus
  <metric>
    name getting_info_from_host
    type counter
    desc Getting info if this counter is rising.
    <labels>
      tag ${tag}
      host ${host_name}
    </labels>
  </metric>
</match>
<match unknown.**>
  @type stdout
</match>
<match nsxt.**>
  @type elasticsearch_dynamic
  host {{.Values.global.elk_elasticsearch_endpoint_host_scaleout}}.{{.Values.global.cluster_region}}.{{.Values.global.domain}}
  port {{.Values.global.elk_elasticsearch_ssl_port}}
  user {{.Values.global.elk_elasticsearch_data_user}}
  password {{.Values.global.elk_elasticsearch_data_password}}
  scheme https
  ssl_verify false
  index_name syslog
  ssl_version TLSv1_2
  logstash_format true
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
</match>
