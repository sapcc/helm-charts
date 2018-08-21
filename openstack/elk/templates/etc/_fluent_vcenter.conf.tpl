<source>                                                                                          
  @type udp                                                                                       
  tag "vcenter"                                                                                   
  format /^(?<message>.*?)$/                                                                      
  bind {{default "0.0.0.0" .Values.fluent_vcenter.vcenter_logs_in_ip}}
  port {{.Values.fluent_vcenter.vcenter_logs_in_port}}                                                                                
</source> 
<source>
  @type udp
  tag "vcenter"
  format /^(?<message>.*?)$/
  bind {{default "0.0.0.0" .Values.fluent_vcenter.esx_logs_in_ip}}
  port {{.Values.fluent_vcenter.esx_logs_in_port}}
</source>
<filter vcenter.**>
  @type parser
  key_name "message"
  format /(?<message>(^.* (?<host_name>{{default "domain.com" .Values.fluent_vcenter.fqdn_match_string}}).*$)|(^.* (?<node_name>{{default "node" .Values.fluent_vcenter.shortname_match_string}}).*$)|(^.*?$))/
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
    tag "OOM.${tag}"
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
<match OOM.**>
  @type prometheus
  <metric>
    name vcenter_dvswitch_out_of_memory
    type counter
    desc Found Error that indicates long timeout on dvs calls
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
