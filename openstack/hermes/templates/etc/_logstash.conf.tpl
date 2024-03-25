input {

{{ range $key, $value := .Values.hermes.rabbitmq.targets }}
{{- $user := $value.user | default $.Values.hermes.rabbitmq.user }}
{{- $host := printf "%s-rabbitmq.monsoon3.svc.kubernetes.%s.%s" $key $.Values.global.region $.Values.global.tld}}
rabbitmq {
    id => {{ printf "logstash_hermes_%s" $key | quote }}
    host => {{ $value.host | default (printf $.Values.hermes.rabbitmq.host_template $key) | quote }}
    user => {{ $user | quote }}
    password => {{ $value.password | quote }}
    port => {{ $.Values.hermes.rabbitmq.port }}
    queue => {{ $value.queue_name | default $.Values.hermes.rabbitmq.queue_name | quote }}
    subscription_retry_interval_seconds => 60
    automatic_recovery => true
    connection_timeout => 1000
    heartbeat => 5
    connect_retry_interval => 60
    durable => {{ $value.durable | default false }}
  }
{{ end }}
}


filter {
  # unwrap messagingv2 envelope
  if [oslo.message] {
    json {
      id => "f02_unwrap_messagingv2_envelope"
      source => "oslo.message"
    }
  }
  # Strip oslo header
  ruby {
    id => "f03_strip_oslo_header"
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
    id => "f04_remove_oslo_stuff"
    remove_field => [ "oslo.message", "oslo.version", "publisher_id", "event_type", "message_id", "priority", "timestamp" ]
  }

  # KEYSTONE TRANSFORMATIONS

  mutate {
    id => "f05_rename_actions"
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
      mutate {
        add_field => { "%{[project]}" => "%{[initiator][project_id]}"  }
        id => "f06a_mutate_initiator_project_id"
        }
    } else if [domain] {
      mutate {
        add_field => { "%{[domain]}" => "%{[initiator][domain_id]}"}
        id => "f06b_mutate_initiator_domain_id"
      }
    }
  }

  # rename initiator user_id into the 'id' field for consistency
  if [initiator][user_id] {
    mutate {
      id => "f07_rename_initiator_user_id"
      replace => { "[initiator][id]" => "%{[initiator][user_id]}" }
      remove_field => ["[initiator][user_id]"]
    }
  }

  # rename intiator domain_name into initiator domain field for consistency.
  if [initiator][domain_name] {
    mutate {
      id => "f08_rename_intiator_domain_name"
      replace => { "[initiator][domain]" => "%{[initiator][domain_name]}" }
      remove_field => ["[initiator][domain_name]"]
    }
  }

  # normalize role-assignment call events
  # see https://sourcegraph.com/github.com/openstack/keystone@81f9fe6fed62ec629804c9367fbb9ebfd584388c/-/blob/keystone/notifications.py#L590
  if [project] {
    mutate {
      id => "f09a_normalize_role_assignments_project"
      replace => { "[target][project_id]" => "%{[project]}" }
      remove_field => ["[project]"]
    }
  } else if [domain] {
    mutate {
      id => "f09b_normalize_role_assignments_domain"
      replace => { "[target][domain_id]" => "%{[domain]}" }
      remove_field => ["[domain]"]
    }
  }
  if [role] {
    ruby {
      id => "f10_ruby_role_set_attachments"
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
      id => "f11_ruby_group_set_attachments"
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
      id => "f12_ruby_project_set_attachments"
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
       id => "f13_replace_target_id_with_user_id"
       replace => { "[target][id]" => "%{[user]}" }
       remove_field => ["[user]"]
     }
  }

  # Enrich keystone events with domain mapping from Metis
  {{- if .Values.logstash.audit }}
  # Fill in lookup fields with "unavailable" to provide the lookup with a field so it doesn't error
  # pipeline shutsdown if a lookup field is not available.

  if ![initiator][project_id] {
    mutate {
      add_field => { "[initiator][project_id]" => "unavailable" }
      id => "f14_add_initiator_project_id_unavailable"
    }
  }

  if ![target][project_id] {
    mutate {
     add_field => { "[target][project_id]" => "unavailable" }
     id => "f15_add_target_project_id_unavailable"
    }
  }

  if ![initiator][id] {
    mutate {
      add_field => { "[initiator][id]" => "unavailable" }
      id => "f16_add_initiator_id_unavailable"
    }
  }

  # With several different event types using jdbc_static, not sure an if makes sense.
  # we will have to handle several events that don't match a query

  jdbc_static {
    id => "jdbc_project_id"
    loaders => [
      {
        id  => "17a_keystone_project_domain"
        query => "select project.name as project_name, project.id as project_id, domain.name as domain_name, domain.id as domain_id from keystone.project join keystone.project domain on project.domain_id = domain.id"
        local_table => "project_domain_mapping"
      },
      {
        id  => "17b_keystone_user_domain"
        query => "select u.id as user_id, CONCAT_WS('', m.local_id, lu.name) as user_name, p.id as domain_id, p.name as domain_name  from keystone.user as u left join keystone.id_mapping m on m.public_id = u.id left join keystone.local_user lu on lu.user_id = u.id left join keystone.project as p on p.id = u.domain_id where p.name <> 'kubernikus'"
        local_table => "user_domain_mapping"
      }
    ]

    local_db_objects => [
      {
        name => "project_domain_mapping"
        index_columns => ["project_id"]
        columns => [
          ["project_name", "varchar(64)"],
          ["project_id", "varchar(64)"],
          ["domain_name", "varchar(64)"],
          ["domain_id", "varchar(64)"]
        ]
      },
      {
        name => "user_domain_mapping"
        index_columns => ["user_id"]
        columns => [
          ["user_id", "varchar(64)"],
          ["user_name", "varchar(64)"],
          ["domain_id", "varchar(64)"],
          ["domain_name", "varchar(64)"]
        ]
      }
    ]

    local_lookups => [
      {
        id => "f17c_project_name_lookup"
        query => "select project_name, domain_id, domain_name from project_domain_mapping where project_id = ?"
        prepared_parameters => ["[initiator][project_id]"]
        target => "project_mapping"
        tag_on_failure => ["Project_Mapping"]
      },
      {
        id => "f17d_target_project_name_lookup"
        query => "select project_name, domain_id, domain_name from project_domain_mapping where project_id = ?"
        prepared_parameters => ["[target][project_id]"]
        target => "target_project_mapping"
        tag_on_failure => ["Target_Project_Mapping"]
      },
      {
        id => "f17e_domain_lookup"
        query => "select user_name, domain_id, domain_name from user_domain_mapping where user_id = ?"
        prepared_parameters => ["[initiator][id]"]
        target => "domain_mapping"
        tag_on_failure => ["Domain_Mapping"]
      }
    ]
    staging_directory => "/tmp/logstash/jdbc_static/import_data"
    loader_schedule => "{{ .Values.logstash.jdbc.schedule }}"
    jdbc_user => {{ .Values.global.metis.user | default "default" | quote }}
    jdbc_password => {{ .Values.global.metis.password | default "default" | quote }}
    jdbc_driver_class => "com.mysql.cj.jdbc.Driver"
    jdbc_driver_library => ""
    jdbc_connection_string => "jdbc:mysql://{{ .Values.logstash.jdbc.service }}.{{ .Values.logstash.jdbc.namespace }}:3306/{{ .Values.logstash.jdbc.db }}"
  }

  if [project_mapping] and [project_mapping][0]{
    # Add Fields to audit events, checking if the field exists first to not overwrite.
    if ![initiator][project_name] {
      mutate {
        id => "f18a_initiator_project_name_adding_initiator_project_name"
        add_field => {
            "[initiator][project_name]" => "%{[project_mapping][0][project_name]}"
        }
      }
    }
    if ![initiator][domain_id] {
      mutate {
        id => "f18b_initiator_project_name_adding_initiator_domain_id"
        add_field => {
            "[initiator][domain_id]" => "%{[project_mapping][0][domain_id]}"
        }
      }
    }
    if ![initiator][project_domain_name] {
      mutate {
        id => "f18c_initiator_project_name_adding_project_domain_name"
        add_field => {
            "[initiator][project_domain_name]" => "%{[project_mapping][0][domain_name]}"
        }
      }
    }

    # Cleanup
    mutate {
      id => "f18d_remove_field_project_mapping"
      remove_field => ["[project_mapping]"]
    }
  }

  if [target_project_mapping] and [target_project_mapping][0]{
    # Add Fields to audit events, checking if the field exists first to not overwrite.
    if ![target][project_name] {
      mutate {
        id => "f19a_adding_target_project_name"
        add_field => {
            "[target][project_name]" => "%{[target_project_mapping][0][project_name]}"
        }
      }
    }
    if ![target][domain_id] {
      mutate {
        id => "f19b_adding_target_domain_id"
        add_field => {
            "[target][domain_id]" => "%{[target_project_mapping][0][domain_id]}"
        }
      }
    }
    if ![target][project_domain_name] {
      mutate {
        id => "f19c_adding_target_domain_name"
        add_field => {
            "[target][project_domain_name]" => "%{[target_project_mapping][0][domain_name]}"
        }
      }
    }

    # Cleanup
    mutate {
      id => "f19d_removing_target_project_mapping"
      remove_field => ["[target_project_mapping]"]
    }
  }

  if [domain_mapping] and [domain_mapping][0]{
    # Add Fields to audit events, checking if the field exists so it doesn't create an array.
    if ![initiator][name] {
      mutate {
        id => "f20a_initiator_name_adding_initiator_name"
        add_field => {
            "[initiator][name]" => "%{[domain_mapping][0][user_name]}"
        }
      }
    }
    if ![initiator][domain_id] {
      mutate {
        id => "f20b_initiator_name_adding_initiator_domain_id"
        add_field => {
            "[initiator][domain_id]" => "%{[domain_mapping][0][domain_id]}"
        }
      }
    }
    if ![initiator][domain] {
      mutate {
        id => "f20c_initiator_name_adding_initiator_domain"
        add_field => {
            "[initiator][domain]" => "%{[domain_mapping][0][domain_name]}"
        }
      }
    }

    # Cleanup
    mutate {
      id => "f20d_removing_domain_mapping"
      remove_field => ["[domain_mapping]"]
    }
  }

  # Cleanup unavailable entries
  if [initiator][project_id] == "unavailable" {
    mutate {
      id => "f20e_removing_initiator_project_id"
      remove_field => ["[initiator][project_id]"]
    }
  }

  if [target][project_id] == "unavailable" {
    mutate {
      id => "f20f_removing_target_project_id"
      remove_field => ["[target][project_id]"]
    }
  }

  if [initiator][id] == "unavailable" {
    mutate {
      id => "f20g_removing_initiator_id"
      remove_field => ["[initiator][id]"]
    }
  }
  {{- end}}

  # Octobus setting Source to TypeURI. Unused in Hermes.
  if [observer][typeURI] {
    mutate {
      id => "f21_octobus_source_to_typeuri"
      add_field => {  "[sap][cc][audit][source]" => "%{[observer][typeURI]}" }
    }
  }

  # Calculate the variable index name part from payload (@metadata will not be part of the event)

  # primary index
  if [initiator][project_id] {
    mutate {
      add_field => { "[@metadata][index]" => "%{[initiator][project_id]}" }
      id => "f22a_calculate_index_name_primary_project_id"
    }
  } else if [target][project_id] and ![initiator][project_id] {
    mutate {
      add_field => { "[@metadata][index]" => "%{[target][project_id]}" }
      id => "f22b_calculate_index_name_primary_target_project_id"
    }
  } else if [initiator][domain_id] {
    mutate {
      add_field => { "[@metadata][index]" => "%{[initiator][domain_id]}" }
      id => "f22c_calculate_index_name_primary_domain_id"
    }
  }

  # secondary index
  # Only add the secondary index if it's different from the primary index
  if [target][project_id] and [@metadata][index] != "%{[target][project_id]}" {
    mutate {
      add_field => { "[@metadata][index2]" => "%{[target][project_id]}" }
      id => "f23a_calculate_index_name_secondary_project_id"
    }
  } else if [target][domain_id] and [@metadata][index] != "%{[target][domain_id]}" {
    mutate {
      add_field => { "[@metadata][index2]" => "%{[target][domain_id]}" }
      id => "f23b_calculate_index_name_secondary_domain_id"
    }
  }


  # remove keystone specific fields after they have been mapped to standard attachments
  mutate {
    id => "f24_remove_keystone_fields_after_mapping"
    remove_field => ["[domain]", "[project]", "[user]", "[role]", "[group]", "[inherited_to_projects]"]
  }

  kv {
    source => "_source"
    id => "f25_kv_source_to_underscore"
    }

  # The following line will create 2 additional
  # copies of each document (i.e. including the
  # original, 3 in total).
  # Each copy will automatically have a "type" field added
  # corresponding to the name given in the array.
  clone {
    id => "f26_clone_events_three_times"
    clones => ['clone_for_audit', 'clone_for_swift', 'clone_for_cc', 'audit']
  }
}

output {
  if [type] == 'clone_for_audit' {
    if ([@metadata][index]) {
      opensearch {
          id => "output_opensearch_clone_for_audit_1"
          index => "audit-%{[@metadata][index]}-%{+YYYY.MM}"
          template => "/hermes-etc/audit.json"
          template_name => "audit"
          template_overwrite => true
          hosts => ["https://{{.Values.hermes_elasticsearch_host}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.hermes_elasticsearch_port}}"]
          auth_type => {
            type => 'basic'
            user => "{{.Values.users.audit.username}}"
            password => "{{.Values.users.audit.password}}"
          }
          retry_max_interval => 10
          validate_after_inactivity => 1000
          ssl => true
          ssl_certificate_verification => true
      }
    } else {
      opensearch {
          id => "output_opensearch_clone_for_audit_2"
          index => "audit-default-%{+YYYY.MM}"
          template => "/hermes-etc/audit.json"
          template_name => "audit"
          template_overwrite => true
          hosts => ["https://{{.Values.hermes_elasticsearch_host}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.hermes_elasticsearch_port}}"]
          retry_max_interval => 10
          validate_after_inactivity => 1000
          auth_type => {
            type => 'basic'
            user => "{{.Values.users.audit.username}}"
            password => "{{.Values.users.audit.password}}"
          }
          ssl => true
          ssl_certificate_verification => true
        }
    }
  }
  # cc the target tenant
  if ([@metadata][index2] and [@metadata][index2] != [@metadata][index] and [type] == 'clone_for_cc') {
    opensearch {
        id => "output_opensearch_clone_for_cc"
        index => "audit-%{[@metadata][index2]}-%{+YYYY.MM}"
        template => "/hermes-etc/audit.json"
        template_name => "audit"
        template_overwrite => true
        hosts => ["https://{{.Values.hermes_elasticsearch_host}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.hermes_elasticsearch_port}}"]
        retry_max_interval => 10
        validate_after_inactivity => 1000
        auth_type => {
          type => 'basic'
          user => "{{.Values.users.audit.username}}"
          password => "{{.Values.users.audit.password}}"
        }
        ssl => true
        ssl_certificate_verification => true
        }
  }

  {{- if .Values.logstash.swift }}
  if [type] == 'clone_for_swift' {
    s3 {
      id => "output_s3_for_swift"
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

  {{- if .Values.logstash.audit }}
  if [type] == 'audit' {
    if (([initiator][domain] == 'Default' and [initiator][name] == 'admin') or [initiator][domain] == 'ccadmin' or [target][project_domain_name] == 'ccadmin' or [initiator][project_domain_name] == 'ccadmin') or ([observer][typeURI] == 'service/security' and [action] == "authenticate" and [outcome] == 'failure') or ([observer][typeURI] == 'service/security' and ([action] == 'create/user') or [action] == 'delete/user') {
      http {
        id => "output_octobus_audit"
        ssl_certificate_authorities => "/usr/share/logstash/config/ca.pem"
        url => "https://{{ .Values.global.forwarding.audit.host }}"
        format => "json"
        http_method => "post"
        automatic_retries => 60
        retry_non_idempotent => true
      }
    }
  }
  {{- end}}
}
