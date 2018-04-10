<source>
  @type syslog
  bind {{default "0.0.0.0" .Values.fluent_vcenter.input_ip}}
  port {{.Values.fluent_vcenter.tcp_input_port}}
  protocol_type tcp
  tag vcenter
  message_format auto
  with_priority true
</source>

<source>
  @type prometheus
  bind {{default "0.0.0.0" .Values.fluent_vcenter.prometheus_ip}}
  port {{.Values.fluent_vcenter.prometheus_port}}
</source>

<match vcenter.**>
  @type copy
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
    name vcenter_dVSwitch_Out_of_Memory
    type counter
    desc Found Error that indicates long timeout on dvs calls
    <labels>
      tag ${tag} 
      host ${host}
    </labels>
  </metric>
</match>