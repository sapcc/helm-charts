input {

# consume Keystone notifications
rabbitmq {
    # only for keystone
    host => "{{.Values.hermes.rabbitmq.keystone.host}}"
    password => "{{.Values.hermes.rabbitmq.keystone.password}}"
    # the remaining parameters are equal
    user => "{{.Values.hermes.rabbitmq.user}}"
    port => {{.Values.hermes.rabbitmq.port}}
    queue => "{{.Values.hermes.rabbitmq.queue_name}}"
    subscription_retry_interval_seconds => 60
    id => "logstash_hermes_keystone"
    automatic_recovery => false
  }

# consume Nova notifications
# rabbitmq {
#     host => "{{.Values.hermes_nova_rabbitmq_host}}"
#     user => "{{.Values.hermes_nova_rabbitmq_user}}"
#     password => "{{.Values.hermes_nova_rabbitmq_password}}"
#     port => {{.Values.hermes_nova_rabbitmq_port}}
#     queue => "{{.Values.hermes_nova_rabbitmq_queue_name}}"
#     subscription_retry_interval_seconds => 60
#     id => "logstash_hermes_nova"
#     automatic_recovery => false
#   }
# }
}


filter {
  # Strip oslo envelope
  mutate {
    remove_field => [ "publisher_id", "event_type", "message_id", "priority", "timestamp" ] 
  }
  ruby {
    code => "
      event.get('payload').each {|k, v|
        event.set(k, v)
      }
      event.remove('payload')
    "
  }

  # KEYSTONE TRANSFORMATIONS
  # Keystone specific transformations to compensate for scope missing from initiator element
  # When scope is missing from initiator, get it from action-specific parameters
  if ![initiator][project_id] and ![initiator][domain_id] {
    if [project] {
      mutate { rename => { "%{[project]}" => "%{[initiator][project_id]}" } }
    } else if [domain] {
      mutate { add_field => { "[initiator][domain_id]" => "%{[initiator][domain_id]}" } }
    }
  }

  # rename initiator user_id into the 'id' field for consistency
  if [initiator][user_id] {
    mutate {
      replace => { "[initiator][id]" => "%{[initiator][user_id]}" } 
      remove_field => ["[initiator][user_id]"]
    }
  }

  # add target projects/domains as attachment
  if ![target][attachments] {
    if [project] {
      ruby {
        code => "
          attachments = event.get('[target][attachments]')
          if attachments.nil?
            attachments = []
          end
          attachments << { 'name' => 'project_id', 'contentType' => '/data/security/project', 'content' => event.get('project') }
          event.set('[target][attachments]', attachments)
        "
    } else if [domain] {
      ruby {
        code => "
          attachments = event.get('[target][attachments]')
          if attachments.nil?
            attachments = []
          end
          attachments << { 'name' => 'domain_id', 'contentType' => '/data/security/domain', 'content' => event.get('domain') }
          event.set('[target][attachments]', attachments)
        "
      }
    }
  }

  if [target][typeURI] == "service/security/account/user" and [user] {
     mutate {
       replace => { "[target][id]" => "%{[user]}" }
       remove_field => ["[user]"]
     }
  }

  # Calculate the variable index name part from payload (@metadata will not be part of the event)

  # primary index
  if [initiator][project_id] {
    mutate { add_field => { "[@metadata][index]" => "%{[initiator][project_id]}" } }
  } else if [initiator][domain_id] {
    mutate { add_field => { "[@metadata][index]" => "%{[initiator][domain_id]}" } }
  }

  # secondary index (keystone only)
  if [project] {
    mutate { add_field => { "[@metadata][index2]" => "%{[project]}" } }
  } else if [domain] {
    mutate { add_field => { "[@metadata][index2]" => "%{[domain]}" } }
  }

  # remove keystone specific fields after they have been mapped to standard attachments 
  mutate {
    remove_field => ["[domain]", "[project]"] 
  }

  kv { source => "_source" }
}

output {
  if ([@metadata][index]) {
    elasticsearch {
        index => "audit-%{[@metadata][index]}-%{+YYYY.MM.dd}"
        template => "/hermes-etc/audit.json"
        template_name => "audit"
        template_overwrite => true
        hosts => ["{{.Values.hermes_elasticsearch_host}}:{{.Values.hermes_elasticsearch_port}}"]
        flush_size => 500
    }
  } else {
    elasticsearch {
        index => "audit-default-%{+YYYY.MM.dd}"
        template => "/hermes-etc/audit.json"
        template_name => "audit"
        template_overwrite => true
        hosts => ["{{.Values.hermes_elasticsearch_host}}:{{.Values.hermes_elasticsearch_port}}"]
        flush_size => 500
    }
  }
  # cc the target tenant
  if ([@metadata][index2] and [@metadata][index2] != [@metadata][index]) {
    elasticsearch {
        index => "audit-%{[@metadata][index2]}-%{+YYYY.MM.dd}"
        template => "/hermes-etc/audit.json"
        template_name => "audit"
        template_overwrite => true
        hosts => ["{{.Values.hermes_elasticsearch_host}}:{{.Values.hermes_elasticsearch_port}}"]
        flush_size => 500
    }
  }
}
