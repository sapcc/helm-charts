input {
  kafka {
        bootstrap_servers => "kafka:{{.Values.monasca_kafka_port_internal}}"
        topics => ["transformed_log"]
        group_id => "logstash-persister"
        client_id => "monasca_log_persister"
        consumer_threads => 12
        codec => json
  }
}

filter {

    date {
        match => ["[log][timestamp]", "UNIX"]
        target => "@timestamp"
    }

    grok {
        match => {
            "[@timestamp]" => "^(?<index_date>\d{4}-\d{2}-\d{2})"
        }
    }

   json {
      source => "message"
    }

    if "dimensions" in [log]  {
      ruby {
        code => "
                fieldHash = event.get('[log][dimensions]')
                fieldHash.each do |key, value|
                event.set(key, value)
                end
                "
      }
    }

    date {
        match => ["creation_time", "UNIX"]
        target => "creation_time"
    }

    mutate {
        add_field => { tenant => "%{[meta][tenantId]}"
                       region => "%{[meta][region]}"
        }
        replace => { message => "%{[log][message]}"
        }
       remove_field => [ "log", "meta", "index_date", "tags", "@version" ]
    }
}

output {
    elasticsearch {
        index => "%{tenant}-%{index_date}"
        document_type => "logs"
        hosts => ["{{.Values.monasca_elasticsearch_endpoint_host_internal}}:{{.Values.monasca_elasticsearch_port_internal}}"]
        user => "{{.Values.monasca_elasticsearch_admin_user}}"
        password => "{{.Values.monasca_elasticsearch_admin_password}}"
        flush_size => 500
    }
}
