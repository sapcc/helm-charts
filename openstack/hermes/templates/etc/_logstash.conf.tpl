input {

{{ range $key, $value := .Values.hermes.rabbitmq.targets }}
rabbitmq {
    id => {{ printf "logstash_hermes_%s" $key | quote }}
    host => {{ $value.host | default (printf $.Values.hermes.rabbitmq.host_template $key) | quote }}
    user => {{ $value.user | default $.Values.hermes.rabbitmq.user | quote }}
    password => {{ $value.password | quote }}
    port => {{ $.Values.hermes.rabbitmq.port }}
    queue => {{ $value.queue_name | default $.Values.hermes.rabbitmq.queue_name | quote }}
    subscription_retry_interval_seconds => 60
    automatic_recovery => true
    heartbeat => 30 
    connect_retry_interval => 60
    durable => {{ $value.durable | default false }}
  }
{{ end }}
}


filter {
  # unwrap messagingv2 envelope
  if [oslo.message] {
    json { source => "oslo.message" }
  }
  # Strip oslo header
  ruby {
    code => "
      v1pl = event.get('payload')
      if !v1pl.nil?
        v1pl.each {|k, v|
          event.set(k, v)
        }
        event.remove('payload')
      end
    "
  }
  # remove all the oslo stuff
  mutate {
    remove_field => [ "oslo.message", "oslo.version", "publisher_id", "event_type", "message_id", "priority", "timestamp" ] 
  }

  # KEYSTONE TRANSFORMATIONS

  mutate {
     gsub => [
        # use proper CADF taxonomy for actions
        "action", "created\.", "create/",
        "action", "deleted\.", "delete/",
        "action", "updated\.", "create/",
        "action", "disabled\.", "disable/",
        "action", "\.", "/",
        # fix the eventTime format to be ISO8601
        "eventTime", '([+\-]\d\d)(\d\d)$', '\1:\2'
     ]
  }

  # Keystone specific transformations to compensate for scope missing from initiator element
  # When scope is missing from initiator, get it from action-specific parameters
  if ![initiator][project_id] and ![initiator][domain_id] {
    if [project] {
      mutate { add_field => { "%{[initiator][project_id]}" => "%{[project]}" } }
    } else if [domain] {
      mutate { add_field => { "%{[initiator][domain_id]}" => "%{[domain]}" } }
    }
  }

  # rename initiator user_id into the 'id' field for consistency
  if [initiator][user_id] {
    mutate {
      replace => { "[initiator][id]" => "%{[initiator][user_id]}" } 
      remove_field => ["[initiator][user_id]"]
    }
  }

  # normalize role-assignment call eventsi
  # see https://sourcegraph.com/github.com/openstack/keystone@81f9fe6fed62ec629804c9367fbb9ebfd584388c/-/blob/keystone/notifications.py#L590
  if [project] {
    mutate {
      replace => { "[target][project_id]" => "%{[project]}" }
      remove_field => ["[project]"]
    }
  } else if [domain] {
    mutate {
      replace => { "[target][domain_id]" => "%{[domain]}" }
      remove_field => ["[domain]"]
    }
  }
  if [role] {
    ruby {
      code => "
        attachments = event.get('[attachments]')
        if attachments.nil?
          attachments = []
        end
        attachments << { 'name' => 'role_id', 'typeURI' => '/data/security/role', 'content' => event.get('role') }
        event.set('[attachments]', attachments)
      "
    }
  }
  if [group] {
    ruby {
      code => "
        attachments = event.get('[attachments]')
        if attachments.nil?
          attachments = []
        end
        attachments << { 'name' => 'group_id', 'typeURI' => '/data/security/group', 'content' => event.get('group') }
        event.set('[attachments]', attachments)
      "
    }
  }
  if [inherited_to_projects] {
    ruby {
      code => "
        attachments = event.get('[attachments]')
        if attachments.nil?
          attachments = []
        end
        attachments << { 'name' => 'inherited_to_projects', 'typeURI' => 'xs:boolean', 'content' => event.get('inherited_to_projects') }
        event.set('[attachments]', attachments)
      "
    }
  }

  # replace target ID with real user ID
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

  # secondary index
  if [target][project_id] {
    mutate { add_field => { "[@metadata][index2]" => "%{[target][project_id]}" } }
  } else if [target][domain_id] {
    mutate { add_field => { "[@metadata][index2]" => "%{[target][domain_id]}" } }
  }

  # remove keystone specific fields after they have been mapped to standard attachments
  mutate {
    remove_field => ["[domain]", "[project]", "[user]", "[role]", "[group]", "[inherited_to_projects]"]
  }

  kv { source => "_source" }

  # The following line will create 2 additional 
  # copies of each document (i.e. including the 
  # original, 3 in total). 
  # Each copy will automatically have a "type" field added 
  # corresponding to the name given in the array.
  clone {
    clones => ['clone_for_audit', 'clone_for_swift', 'clone_for_cc']
  }
}

output {
  if [type] == 'clone_for_audit' {
    if ([@metadata][index]) {
      elasticsearch {
          index => "audit-%{[@metadata][index]}-6-%{+YYYY.MM}"
          template => "/hermes-etc/audit.json"
          template_name => "audit"
          template_overwrite => true
          hosts => ["{{.Values.hermes_elasticsearch_host}}:{{.Values.hermes_elasticsearch_port}}"]
          # retry_max_interval default 64
          retry_max_interval => 10
      }
    } else {
      elasticsearch {
          index => "audit-default-6-%{+YYYY.MM}"
          template => "/hermes-etc/audit.json"
          template_name => "audit"
          template_overwrite => true
          hosts => ["{{.Values.hermes_elasticsearch_host}}:{{.Values.hermes_elasticsearch_port}}"]
          # retry_max_interval default 64
          retry_max_interval => 10
      }
    }
  }
  # cc the target tenant
  if ([@metadata][index2] and [@metadata][index2] != [@metadata][index] and [type] == 'clone_for_cc') {
    elasticsearch {
        index => "audit-%{[@metadata][index2]}-6-%{+YYYY.MM}"
        template => "/hermes-etc/audit.json"
        template_name => "audit"
        template_overwrite => true
        hosts => ["{{.Values.hermes_elasticsearch_host}}:{{.Values.hermes_elasticsearch_port}}"]
        # retry_max_interval default 64
        retry_max_interval => 10
    }
  }

  {{ if .Values.logstash.swift -}}
  if [type] == 'clone_for_swift' {
    s3{
      endpoint => "{{.Values.logstash.endpoint}}"
      access_key_id => "{{.Values.logstash.access_key_id}}"
      secret_access_key => "{{.Values.logstash.secret_access_key}}"
      region => "{{.Values.logstash.region}}"
      bucket => "{{.Values.logstash.bucket}}"
      prefix => "{{.Values.logstash.prefix}}"
      time_file => {{.Values.logstash.time_file}}
      #encoding => "gzip"
      codec => "json_lines"
      validate_credentials_on_root_bucket => false
      additional_settings => {
        "force_path_style" => true
      }
    }
  }
  {{- end}}
}
