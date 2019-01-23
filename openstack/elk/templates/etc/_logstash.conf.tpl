input {
  udp {
    port  => {{.Values.elk_logstash_input_netflow_port}}
    codec => netflow
    tags => ["netflow"]
  }
  udp {
    port  => {{.Values.elk_logstash_input_syslog_port}}
    type = > syslog
  }
  tcp {
    port  => {{.Values.elk_logstash_input_syslog_port}}
    type = > syslog
  }
}

filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}


output {
if "netflow" in [tags] {
  elasticsearch {
    index => "netflow-%{+YYYY.MM.dd}"
    template => "/elk-etc/netflow.json"
    template_name => "netflow"
    template_overwrite => true
    hosts => ["{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}"]
    user => "{{.Values.elk_elasticsearch_admin_user}}"
    password => "{{.Values.elk_elasticsearch_admin_password}}"
    flush_size => 500
  }
}
else {
  elasticsearch {
    index => "syslog-%{+YYYY.MM.dd}"
    template => "/elk-etc/syslog.json"
    template_name => "syslog"
    template_overwrite => true
    hosts => ["{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}"]
    user => "{{.Values.elk_elasticsearch_admin_user}}"
    password => "{{.Values.elk_elasticsearch_admin_password}}"
    flush_size => 500
  }
}
}
