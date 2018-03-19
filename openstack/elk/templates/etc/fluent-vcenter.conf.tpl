<source>
  @type syslog
  port {{.Values.fluent_vcenter_tcp_input_port}}
  bind 0.0.0.0
  protocol_type tcp
  tag vcenter
  message_format auto
  with_priority true
</source>

<source>
  @type prometheus
</source>

<match vcenter.**>
  @type copy
  <store>
    @type rewrite_tag_filter


    
    <rule>
      key message
      pattern success
      tag success.${tag}
    </rule>
    <rule>
      key message
      pattern fail
      tag fail.${tag}
    </rule>
    <rule>
      key message
      pattern .+
      tag alltherest.${tag}
    </rule>
  </store>
</match>

<match success.**>
  @type prometheus
  <metric>
    name success counter
    type counter
    desc Found success event in vCenter log
    <labels>
      tag ${tag}
      host ${host}
    </labels>
  </metric>
</match>

<match fail.**>
  @type prometheus
  <metric>
    name failure counter
    type counter
    desc Found a failure in vCenter log
    <labels>
      tag ${tag} 
      host ${host}
    </labels>
  </metric>
</match>