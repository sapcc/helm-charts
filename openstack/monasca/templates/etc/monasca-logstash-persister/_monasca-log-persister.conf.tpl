input {
  
  kafka {
        bootstrap_servers => "kafka:{{.Values.monasca_kafka_port_internal}}"
        topics => ["transformed-log"]
        group_id => "logstash-persister"
        client_id => "monasca_log_persister"
        consumer_threads => 12
  }
}

filter {
    mutate {
        add_field => {
            olaf => "%{meta}"
            olaf1 => "%{tenantId}"
            message => "%{[log][message]}"
            log_level => "%{[log][level]}"
            tenant => "%{[meta][tenantId]}"
            region => "%{[meta][region]}"
        }
#        remove_field => ["@version" ,"_index_date", "meta", "log"]
    }

}

#output {
#    elasticsearch {
#        index => "%{[meta][tenantId]}-%{index_date}"
#        document_type => "logs"
#        hosts => ["{{.Values.monasca_elasticsearch_endpoint_host_internal}}:{{.Values.monasca_elasticsearch_port_internal}}"]
#        user => "{{.Values.monasca_elasticsearch_admin_user}}"
#        password => "{{.Values.monasca_elasticsearch_admin_password}}"
#        flush_size => 500
#    }
#}

output {
    kafka {
        bootstrap_servers => "kafka:{{.Values.monasca_kafka_port_internal}}"
        topic_id => "olaf-log"
        reconnect_backoff_ms => 1000
        retries => 10
        retry_backoff_ms => 1000
        }
}
