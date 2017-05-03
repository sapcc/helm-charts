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
  mutate {
    gsub => [
      "message", "\", [0-9], \"", " = ",
      "message", "\], \[", ",",
      "message", "\]\]", "]",
      "message", "\[\[", "["
    ]
  }


  json {
    source => "message"
  }

  kv {
    source => "traits"
    remove_field => "traits"
  }

  if ![tenant_id] and "" in [project] {
    mutate { add_field => { "tenant_id" => "%{[project]}" } }
  }
}

output {
  if ([tenant_id]) {
    elasticsearch {
        index => "audit-%{tenant_id}-%{+YYYY.MM.dd}"
        hosts => ["{{.Values.monasca_elasticsearch_endpoint_host_internal}}:{{.Values.monasca_elasticsearch_port_internal}}"]
        user => "{{.Values.monasca_elasticsearch_audit_user}}"
        password => "{{.Values.monasca_elasticsearch_audit_password}}"
        flush_size => 500
    }
  }
    else {
    elasticsearch {
        index => "audit-default-%{+YYYY.MM.dd}"
        hosts => ["{{.Values.monasca_elasticsearch_endpoint_host_internal}}:{{.Values.monasca_elasticsearch_port_internal}}"]
        user => "{{.Values.monasca_elasticsearch_audit_user}}"
        password => "{{.Values.monasca_elasticsearch_audit_password}}"
        flush_size => 500
    }
  }
}
