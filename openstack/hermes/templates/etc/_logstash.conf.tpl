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
#rabbitmq {
#    host => "{{.Values.hermes_legacy_rabbitmq_host}}"
#    user => "{{.Values.hermes_legacy_rabbitmq_user}}"
#    password => "{{.Values.hermes_legacy_rabbitmq_password}}"
#    port => {{.Values.hermes_legacy_rabbitmq_port}}
#    queue => "{{.Values.hermes_legacy_rabbitmq_queue_name}}"
#    subscription_retry_interval_seconds => 60
#    id => "logstash_legacy_hermes"
#    automatic_recovery => false
#  }
}

filter {
  if "identity.authenticate" in [event_type] {
    drop { }
  }
  # Drop DNS events as they are not CADF format, reevaluate later.
  #  if "dns." in [event_type] {
  #    drop { }
  #  }
  if ![tenant_id] and "" in [project] {
    mutate { add_field => { "tenant_id" => "%{[project]}" } }
  }
  if ([payload][tenant_id]) {
    mutate { add_field => { "tenant_id" => "%{[payload][tenant_id]}" } }
  }
  # Created, and Deleted have same mutate.
  if "identity.role_assigned." in [event_type] {
    mutate { add_field => { "tenant_id" => "%{[payload][project]}" } }
  }
  # Don't see a project id, there's a default domain id on these events
  if "identity.user.updated" in [event_type] {
    mutate { add_field => { "tenant_id" => "%{[payload][initiator][domain_id]}" } } 
  }
  # The target project is valid here. 
  if "identity.project" in [event_type] {
    mutate { add_field => { "domain_id" => "%{[payload][target][id]}" } }
    }
  if "identity.OS-TRUST" in [event_type] {
    mutate { add_field => { "tenant_id" => "%{[payload][initiator][project_id]}" } }
    }
  kv { source => "_source" }
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
  else if ([domain_id]) {
    elasticsearch {
        index => "audit-%{domain_id}-%{+YYYY.MM.dd}"
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
  if "logstash_legacy_hermes" in [id] {
    file {
     path => "/usr/share/logstash/legacy-%{+YYYY-MM-dd}"
    }
  }
}
