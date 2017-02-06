input {
  
  kafka {
    zk_connect => "zk:{{.Values.monasca_zookeeper_port_internal}}"
    topic_id => "transformed-log"
    group_id => "logstash-persister"
    consumer_restart_on_error => true
    consumer_threads => 12
    consumer_restart_sleep_ms => 1000
    rebalance_max_retries => 50
    rebalance_backoff_ms => 5000
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

    if "dimensions" in [log] {
        ruby {
            code => "
                fieldHash = event['log']['dimensions']
                fieldHash.each do |key, value|
                    event[key] = value
                end
            "
        }
    }

    if "application_type" in [log] {
        mutate {
            add_field => {
                application_type => "%{[log][application_type]}"
            }
        }
    } else {
        mutate {
            add_field => {
                application_type => ""
            }
        }
    }

    mutate {
        add_field => {
            message => "%{[log][message]}"
            log_level => "%{[log][level]}"
            tenant => "%{[meta][tenantId]}"
            region => "%{[meta][region]}"
        }
        remove_field => ["@version" ,"_index_date", "meta", "log"]
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
