input {
  udp {
    port  => {{.Values.elk_logstash_input_udp_port}}
    codec => netflow
  }
}

output {
    elasticsearch {
        index => "netflow-%{+YYYY.MM.dd}"
        template => "/elk-etc/"
        template_name => "netflow"
        template_overwrite => true
        hosts => ["{{.Values.elk_elasticsearch_endpoint_host_internal}}:{{.Values.elk_elasticsearch_port_internal}}"]
        user => "{{.Values.elk_elasticsearch_admin_user}}"
        password => "{{.Values.elk_elasticsearch_admin_password}}"
        flush_size => 500
    }
}
