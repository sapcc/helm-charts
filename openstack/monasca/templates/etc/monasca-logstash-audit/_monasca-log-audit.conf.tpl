input {
  kafka {
        bootstrap_servers => "kafka:{{.Values.monasca_kafka_port_internal}}"
        topics => ["events-cadf"]
        group_id => "logstash-audit"
        client_id => "logstash-audit"
        consumer_threads => 12
  }
}

filter {
    date {
        match => ["[log][timestamp]", "UNIX"]
        target => "@timestamp"
    }

    date {
        match => ["creation_time", "UNIX"]
        target => "creation_time"
    }

    grok {
        match => {
            "[@timestamp]" => "^(?<index_date>\d{4}-\d{2}-\d{2})"
            add_tag => [ "timestamp_added" ]
        }
    }
}

output {
    elasticsearch {
        index => "audit-%{index_date}"
        hosts => ["{{.Values.monasca_elasticsearch_endpoint_host_internal}}:{{.Values.monasca_elasticsearch_port_internal}}"]
        user => "{{.Values.monasca_elasticsearch_audit_user}}"
        password => "{{.Values.monasca_elasticsearch_audit_password}}"
        flush_size => 500
    }
}
