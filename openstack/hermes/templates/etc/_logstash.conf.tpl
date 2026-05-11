input {

{{ range $replica_name, $replica := .Values.hermes.rabbitmq.targets }}
{{- $host := printf "%s-rabbitmq.monsoon3.svc.kubernetes.%s.%s" $replica_name $.Values.global.region $.Values.global.tld}}
rabbitmq {
    id => "{{ printf "logstash_hermes_%s" $replica_name }}"
    host => "{{ $replica.host | default (printf $.Values.hermes.rabbitmq.host_template $replica_name) }}"
    user => "${RABBITMQ_{{ upper $replica_name }}_USER}"
    password => "${RABBITMQ_{{ upper $replica_name }}_PASSWORD}"
    port => {{ $.Values.hermes.rabbitmq.port }}
    queue => "{{ $replica.queue_name | default $.Values.hermes.rabbitmq.queue_name }}"
    subscription_retry_interval_seconds => 60
    automatic_recovery => true
    connection_timeout => 1000
    heartbeat => 5
    connect_retry_interval => 60
    durable => {{ $replica.durable | default false }}
  }
{{ end }}
}


filter {
  # Drop events with action "read/list"
  # Barbican records reads, but has multiple events per read. 
  # This will keep it to one event per action 
  if ([action] == "read/list" or [action] == "read/get") {
    drop { }
  }

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
       "action", "updated\.", "update/",
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

  # Keystone condition for target id and typeURI moving to project_id for consistency and enrichment
  if [target][id] and [target][typeURI] == "data/security/project" {
    mutate {
      id => "f06c_move_target_id_to_project_id"
      add_field => { "[target][project_id]" => "%{[target][id]}" }
      remove_field => [ "[target][id]" ]
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

  # SIEM dependency: The Octobus forwarding condition requires [initiator][domain]
  # which is only available via JDBC domain lookup from Metis. This enrichment must
  # remain until the SIEM integration is replaced with one that does not require
  # domain name resolution at ingestion time.
  # TODO: Remove jdbc_static entirely once SIEM replacement is complete.
  {{- if .Values.logstash.audit }}

  if ![initiator][id] {
    mutate {
      add_field => { "[initiator][id]" => "unavailable" }
      id => "f16_add_initiator_id_unavailable"
    }
  }

  # Log and Correct malformed target.project_id
  # Addresses some castellum events having multiple duplicate target.project_id's
  # with debug logging to track down the issue further.
  ruby {
    id => "f27_correct_project_id"
    code => '
      project_id = event.get("[target][project_id]")
      if project_id.is_a?(Array) || (project_id.is_a?(String) && project_id.include?(","))
        original_project_id = project_id
        corrected_id = project_id.is_a?(Array) ? project_id.first : project_id.split(",").first.strip
        event.set("[target][project_id]", corrected_id)
        logger.warn("Corrected malformed target.project_id from #{original_project_id.inspect} to #{corrected_id}")
      end
    '
  }

  jdbc_static {
    id => "jdbc_domain_lookup"
    loaders => [
      {
        id  => "17b_keystone_user_domain"
        query => "select u.id as user_id, p.id as domain_id, p.name as domain_name  from keystone.user as u left join keystone.project as p on p.id = u.domain_id where p.name <> 'kubernikus'"
        local_table => "user_domain_mapping"
      }
    ]

    local_db_objects => [
      {
        name => "user_domain_mapping"
        index_columns => ["user_id"]
        columns => [
          ["user_id", "varchar(64)"],
          ["domain_id", "varchar(64)"],
          ["domain_name", "varchar(64)"]
        ]
      }
    ]

    local_lookups => [
      {
        id => "f17e_domain_lookup"
        query => "select domain_id, domain_name from user_domain_mapping where user_id = ?"
        prepared_parameters => ["[initiator][id]"]
        target => "domain_mapping"
        tag_on_failure => ["Domain_Mapping"]
      }
    ]
    staging_directory => "/tmp/logstash/jdbc_static/import_data"
    loader_schedule => "{{ .Values.logstash.jdbc.schedule }}"
    jdbc_user => "${METIS_USER}"
    jdbc_password => "${METIS_PASSWORD}"
    jdbc_driver_class => "com.mysql.cj.jdbc.Driver"
    jdbc_driver_library => ""
    jdbc_connection_string => "jdbc:mysql://{{ .Values.logstash.jdbc.service }}.{{ .Values.logstash.jdbc.namespace }}:3306/{{ .Values.logstash.jdbc.db }}"
  }



  if [domain_mapping] and [domain_mapping][0]{
    # Populate initiator domain fields for SIEM forwarding (Octobus).
    # NOTE: initiator.name (user_name/I-number) intentionally NOT populated — PII.
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

  # Cleanup unavailable entry used for domain lookup
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

  # Build array of tenant IDs for document-level isolation
  ruby {
    id => "f26_build_tenant_ids_array"
    code => "
      tenant_ids = []

      # Add primary tenant ID
      primary_tenant = event.get('[@metadata][index]')
      if !primary_tenant.nil? && primary_tenant != '' && primary_tenant != 'unavailable'
        tenant_ids << primary_tenant
      end

      # Add secondary tenant ID if different
      secondary_tenant = event.get('[@metadata][index2]')
      if !secondary_tenant.nil? && secondary_tenant != '' && secondary_tenant != primary_tenant && secondary_tenant != 'unavailable'
        tenant_ids << secondary_tenant
      end

      # Fallback to Default tenant if no valid tenants found
      if tenant_ids.empty?
        tenant_ids << 'Default'
      end

      # Set the tenant_ids field
      event.set('tenant_ids', tenant_ids)
    "
  }

  # The following line will create 2 additional
  # copies of each document (i.e. including the
  # original, 3 in total).
  # Each copy will automatically have a "type" field added
  # corresponding to the name given in the array.
  clone {
    id => "f27_clone_events"
    clones => ['clone_for_audit', 'clone_for_swift', 'audit']
  }
}

output {
  if [type] == 'clone_for_audit' {
    opensearch {
      id => "output_opensearch_datastream"
      index => "hermes"
      action => "create"
      manage_template => false
      hosts => ["https://{{.Values.hermes_elasticsearch_host}}.{{.Values.global.region}}.{{.Values.global.tld}}:{{.Values.hermes_elasticsearch_port}}"]
      auth_type => {
        type => 'basic'
        user => "${OPENSEARCH_USER}"
        password => "${OPENSEARCH_PASSWORD}"
      }
      retry_max_interval => 10
      validate_after_inactivity => 1000
      ssl => true
      ssl_certificate_verification => true
    }
  }
  # Multi-tenant access is now handled via tenant_ids array field
  # No separate output needed for secondary tenants

  {{- if .Values.logstash.swift }}
  if [type] == 'clone_for_swift' {
    s3 {
      id => "output_s3_for_swift"
      endpoint => "{{.Values.logstash.endpoint}}"
      access_key_id => "${SWIFT_ACCESS_KEY}"
      secret_access_key => "${SWIFT_SECRET_KEY}"
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
  # SIEM forwarding to Octobus — forwards security-relevant audit events.
  # NOTE: [initiator][domain] depends on jdbc_static domain lookup above.
  # TODO: Replace domain-name matching with domain_id once SIEM supports it.
  if [type] == 'audit' {
    if ([initiator][domain] == 'Default' or [initiator][domain] == 'ccadmin') or ([observer][typeURI] == 'service/security' and [action] == "authenticate" and [outcome] == 'failure') or ([observer][typeURI] == 'service/security' and ([action] == 'create/user') or [action] == 'delete/user') or [observer][typeURI] == 'service/data/security/keymanager' or [target][typeURI] == 'data/security/project' {
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
