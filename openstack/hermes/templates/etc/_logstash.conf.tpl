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
rabbitmq {
    host => "{{.Values.hermes_legacy_rabbitmq_host}}"
    user => "{{.Values.hermes_legacy_rabbitmq_user}}"
    password => "{{.Values.hermes_legacy_rabbitmq_password}}"
    port => {{.Values.hermes_legacy_rabbitmq_port}}
    queue => "{{.Values.hermes_legacy_rabbitmq_queue_name}}"
    subscription_retry_interval_seconds => 60
    id => "logstash_legacy_hermes"
    automatic_recovery => false
  }
}

filter {
  # Remove unneeded authenticate, not useful for auditing.
  if "identity.authenticate" in [event_type] {
    drop { }
  }
  
  # Designate has duplicate messages for zone and domain, drop zone as that's consistent with other similar services.
  if "dns.zone." in [event_type] {
    drop { }
  }
  # Drop all DNS exists messages as they are periodic messages that are not useful for us.
  if "dns.domain.exists" in [event_type] {
    drop { }
  }
  # Remove Canary Tests 
  if "Canary_test" in [payload][description] {
    drop { }
  }
  # Map Designate Fields to standardized CADF format.
  if "dns." in [event_type] {
    mutate { add_field => { "[payload][eventTime]" => "%{[@timestamp]}" } }
    mutate { add_field => { "[payload][target][typeURI]" => "dns/domain" } }
    mutate { add_field => { "[payload][target][id]" => "%{[payload][id]}" } }
    # Docs say it's _context_user_id , we have _context_user that doesn't look right. TODO: sort it out.
    mutate { add_field => { "[payload][initiator][user_id]" => "%{[_context_user]}" } }
  }
  # Remove Auth Token from Designate Events, security risk.
  if "" in [_context_auth_token] {
    mutate { remove_field => ["_context_auth_token"] }
  }
  

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
  # Write out designate events to file until we develop a proper cadf mapping
  #if "dns." in [event_type] {
  #  file {
  #   path => "/usr/share/logstash/designate-%{+YYYY-MM-dd}"
  #  }
  #}
  # else if ([tenant_id]) {
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
}
