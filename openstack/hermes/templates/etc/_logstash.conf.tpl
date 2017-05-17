input {
rabbitmq {
    host => "{{.Values.hermes_rabbitmq_host}}"
    user => "{{.Values.hermes_rabbitmq_user}}"
    password => "{{.Values.hermes_rabbitmq_password}}"
    port => {{.Values.hermes_rabbitmq_port}}
    queue => "{{.Values.hermes_rabbitmq_queue_name}}"
    subscription_retry_interval_seconds => 60
    id => "logstash_hermes"
    automatic_recovery => false
  }
}

filter {
  if ![tenant_id] and "" in [project] {
    mutate { add_field => { "tenant_id" => "%{[project]}" } }
  }
  if ([payload][tenant_id]) {
    mutate { add_field => { "tenant_id" => "%{[payload][tenant_id]}" } }
  }
}

output {
  if ([tenant_id]) {
    elasticsearch {
        index => "audit-%{tenant_id}-%{+YYYY.MM.dd}"
        template => "/hermes-etc/audit.json"
        template_name => "audit"
        template_overwrite => true
        hosts => ["{{.Values.hermes_elasticsearch_host}}:{{.Values.hermes_elasticsearch_port}}"]
        flush_size => 500
    }
  }
    else {
    elasticsearch {
        index => "audit-default-%{+YYYY.MM.dd}"
        template => "/hermes-etc/audit.json"
        template_name => "audit"
        template_overwrite => true
        hosts => ["{{.Values.hermes_elasticsearch_host}}:{{.Values.hermes_elasticsearch_port}}"]
        flush_size => 500
    }
  }
}
