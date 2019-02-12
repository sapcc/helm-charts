input {
  udp {
    port  => {{.Values.elk_logstash_input_netflow_port}}
    type => netflow
  }
  udp {
    port  => {{.Values.elk_logstash_input_syslog_port}}
    type => syslog
  }
  tcp {
    port  => {{.Values.elk_logstash_input_syslog_port}}
    type => syslog
}
}

output {
if  [type] == "netflow" {
  elasticsearch {
    index => "netflow-%{+YYYY.MM.dd}"
    template => "/elk-etc/netflow.json"
    template_name => "netflow"
    template_overwrite => true
    hosts => ["{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}"]
    user => "{{.Values.elk_elasticsearch_admin_user}}"
    password => "{{.Values.elk_elasticsearch_admin_password}}"
  }
}
elseif [type] == "syslog" {
  elasticsearch {
    index => "syslog-%{+YYYY.MM.dd}"
    template => "/elk-etc/syslog.json"
    template_name => "syslog"
    template_overwrite => true
    hosts => ["{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}"]
    user => "{{.Values.elk_elasticsearch_admin_user}}"
    password => "{{.Values.elk_elasticsearch_admin_password}}"
  }
}
}
