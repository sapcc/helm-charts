filter {
        if [source][domain] and [destination][domain] {
            jdbc_static {
              id => "jdbc"
              loaders =>[
                  {
                  id => "metisdb"
                  query => "select ip_address, floating_ip_id, port_id, project, project_id, domain, domain_id, network, network_id, subnet, subnet_id,
                  subnetpool, subnetpool_id, router, router_id, instance_id, owner, cost_object, cost_object_type, 
                  primary_contact, primary_contact_email, business_criticality from openstack_ips"
                  local_table => "ips"
                  }
              ]

              local_db_objects => [
                  {
                  name => "ips"
                  index_columns => ["ip_address"]
                  columns => [
                      ["ip_address", "varchar(64)"],
                      ["floating_ip_id", "varchar(36)"],
                      ["port_id", "varchar(36)" ],
                      ["project", "varchar(64)" ],
                      ["project_id", "varchar(64)" ],
                      ["domain", "varchar(64)" ],
                      ["domain_id", "varchar(36)" ],
                      ["network", "varchar(255)"],
                      ["network_id", "varchar(36)" ],
                      ["subnet", "varchar(255)"],
                      ["subnet_id", "varchar(36)" ],
                      ["subnetpool", "varchar(255)"],
                      ["subnetpool_id", "varchar(36)" ],
                      ["router", "varchar(255)"],
                      ["router_id", "varchar(36)" ],
                      ["instance_id", "varchar(255)"],
                      ["owner", "varchar(255)"],
                      ["cost_object", "varchar(64)"],
                      ["cost_object_type", "varchar(64)"],
                      ["primary_contact", "varchar(64)"],
                      ["primary_contact_email", "varchar(255)"],
                      ["business_criticality", "varchar(64)"]
                  ]
                  }
              ]

              local_lookups => [
                  {
                  id => "lookup_source"
                  query => "select domain, domain_id, project, project_id, port_id, network, network_id, subnet, subnet_id, subnetpool, subnetpool_id, router, router_id, instance_id, cost_object, cost_object_type, primary_contact, primary_contact_email, business_criticality from ips where ip_address = ?"
                  prepared_parameters => ["[source][domain]"]
                  target => "source_data"
                  tag_on_failure => ["JDBC_LOOKUP_FAILED"]
                  },
                  {
                  id => "lookup_destination"
                  query => "select domain, domain_id, project, project_id, port_id, network, network_id, subnet, subnet_id, subnetpool, subnetpool_id, router, router_id, instance_id, cost_object, cost_object_type, primary_contact, primary_contact_email, business_criticality from ips where ip_address = ?"
                  prepared_parameters => ["[destination][domain]"]
                  target => "destination_data"
                  tag_on_failure => ["JDBC_LOOKUP_FAILED"]
                  }
              ]
            
              staging_directory => "/tmp/logstash/jdbc_static/import_data"
              loader_schedule => "{{ .Values.jdbc.schedule }}"
              jdbc_user => "{{ .Values.global.metis.user }}"
              jdbc_password => "${METIS_PASSWORD}"
              jdbc_driver_class => "com.mysql.cj.jdbc.Driver"
              jdbc_driver_library => ""
              jdbc_connection_string => "jdbc:mysql://{{ .Values.jdbc.service }}.{{ .Values.jdbc.namespace }}:3306/{{ .Values.jdbc.db }}"
              }
          }

          if [source_data] and [source_data][0] {
                  mutate {
                      add_field => { "[source][cc_port_id]" => "%{[source_data][0][port_id]}"
                                     "cc_port_id" => "%{[source_data][0][port_id]}"
                                     "[source][cc_domain]" => "%{[source_data][0][domain]}"
                                     "cc_domain" => "%{[source_data][0][domain]}"
                                     "[source][cc_domain_id]" => "%{[source_data][0][domain_id]}"
                                     "cc_domain_id" => "%{[source_data][0][domain_id]}"
                                     "[source][cc_project]" => "%{[source_data][0][project]}"
                                     "cc_project" => "%{[source_data][0][project]}"
                                     "[source][cc_project_id]" => "%{[source_data][0][project_id]}"
                                     "cc_project_id" => "%{[source_data][0][project_id]}"
                                     "[source][cc_network]" => "%{[source_data][0][network]}"
                                     "cc_network" => "%{[source_data][0][network]}"
                                     "[source][cc_network_id]" => "%{[source_data][0][network_id]}"
                                     "cc_network_id" => "%{[source_data][0][network_id]}"
                                     "[source][cc_subnet]" => "%{[source_data][0][subnet]}"
                                     "cc_subnet" => "%{[source_data][0][subnet]}"
                                     "[source][cc_subnet_id]" => "%{[source_data][0][subnet_id]}"
                                     "cc_subnet_id" => "%{[source_data][0][subnet_id]}"
                                     "[source][cc_subnetpool]" => "%{[source_data][0][subnetpool]}"
                                     "cc_subnetpool" => "%{[source_data][0][subnetpool]}"
                                     "[source][cc_subnetpool_id]" => "%{[source_data][0][subnetpool_id]}"
                                     "cc_subnetpool_id" => "%{[source_data][0][subnetpool_id]}"
                                     "[source][cc_router]" => "%{[source_data][0][router]}"
                                     "cc_router" => "%{[source_data][0][router]}"
                                     "[source][cc_router_id]" => "%{[source_data][0][router_id]}"
                                     "cc_router_id" => "%{[source_data][0][router_id]}"
                                     "[source][cc_instance_id]" => "%{[source_data][0][instance_id]}"
                                     "cc_instance_id" => "%{[source_data][0][instance_id]}"
                                     "[source][cc_cost_object]" => "%{[source_data][0][cost_object]}"
                                     "cc_cost_object" => "%{[source_data][0][cost_object]}"
                                     "[source][cc_cost_object_type]" => "%{[source_data][0][cost_object_type]}"
                                     "cc_cost_object_type" => "%{[source_data][0][cost_object_type]}"
                                     "[source][cc_primary_contact]" => "%{[source_data][0][primary_contact]}"
                                     "cc_primary_contact" => "%{[source_data][0][primary_contact]}"
                                     "[source][cc_primary_contact_email]" => "%{[source_data][0][primary_contact_email]}"
                                     "cc_primary_contact_email" => "%{[source_data][0][primary_contact_email]}"
                                     "[source][cc_business_criticality]" => "%{[source_data][0][business_criticality]}"
                                     "cc_business_criticality" => "%{[source_data][0][business_criticality]}"
                  }
              }
          }
          mutate {
                  remove_field => [ "source_data" ]
        }

          if [destination_data] and [destination_data][0] {
                  mutate {
                      add_field => { "[destination][cc_port_id]" => "%{[destination_data][0][port_id]}"
                                     "cc_port_id" => "%{[destination_data][0][port_id]}"
                                     "[destination][cc_domain]" => "%{[destination_data][0][domain]}"
                                     "cc_domain" => "%{[destination_data][0][domain]}"
                                     "[destination][cc_domain_id]" => "%{[destination_data][0][domain_id]}"
                                     "cc_domain_id" => "%{[destination_data][0][domain_id]}"
                                     "[destination][cc_project]" => "%{[destination_data][0][project]}"
                                     "cc_project" => "%{[destination_data][0][project]}"
                                     "[destination][cc_project_id]" => "%{[destination_data][0][project_id]}"
                                     "cc_project_id" => "%{[destination_data][0][project_id]}"
                                     "[destination][cc_network]" => "%{[destination_data][0][network]}"
                                     "cc_network" => "%{[destination_data][0][network]}"
                                     "[destination][cc_network_id]" => "%{[destination_data][0][network_id]}"
                                     "cc_network_id" => "%{[destination_data][0][network_id]}"
                                     "[destination][cc_subnet]" => "%{[destination_data][0][subnet]}"
                                     "cc_subnet" => "%{[destination_data][0][subnet]}"
                                     "[destination][cc_subnet_id]" => "%{[destination_data][0][subnet_id]}"
                                     "cc_subnet_id" => "%{[destination_data][0][subnet_id]}"
                                     "[destination][cc_subnetpool]" => "%{[destination_data][0][subnetpool]}"
                                     "cc_subnetpool" => "%{[destination_data][0][subnetpool]}"
                                     "[destination][cc_subnetpool_id]" => "%{[destination_data][0][subnetpool_id]}"
                                     "cc_subnetpool_id" => "%{[destination_data][0][subnetpool_id]}"
                                     "[destination][cc_router]" => "%{[destination_data][0][router]}"
                                     "cc_router" => "%{[destination_data][0][router]}"
                                     "[destination][cc_router_id]" => "%{[destination_data][0][router_id]}"
                                     "cc_router_id" => "%{[destination_data][0][router_id]}"
                                     "[destination][cc_instance_id]" => "%{[destination_data][0][instance_id]}"
                                     "cc_instance_id" => "%{[destination_data][0][instance_id]}"
                                     "[destination][cc_cost_object]" => "%{[destination_data][0][cost_object]}"
                                     "cc_cost_object" => "%{[destination_data][0][cost_object]}"
                                     "[destination][cc_cost_object_type]" => "%{[destination_data][0][cost_object_type]}"
                                     "cc_cost_object_type" => "%{[destination_data][0][cost_object_type]}"
                                     "[destination][cc_primary_contact]" => "%{[destination_data][0][primary_contact]}"
                                     "cc_primary_contact" => "%{[destination_data][0][primary_contact]}"
                                     "[destination][cc_primary_contact_email]" => "%{[destination_data][0][primary_contact_email]}"
                                     "cc_primary_contact_email" => "%{[destination_data][0][primary_contact_email]}"
                                     "[destination][cc_business_criticality]" => "%{[destination_data][0][business_criticality]}"
                                     "cc_business_criticality" => "%{[destination_data][0][business_criticality]}"
                  }
              }
          }
          mutate {
                  remove_field => [ "destination_data" ]
                  }
          ruby {
                  code => '
                      event.to_hash.each { |k,v|
                          if v.kind_of? String
                              if v == "NULL"
                                  event.remove(k)
                              end
                          end
                      }
                      event.get("[destination]").to_hash.each { |k,v|
                          if v.kind_of? String
                              if v == "NULL"
                                  event.remove("[destination]" + "[" + k + "]")
                              end
                          end
                      }
                      event.get("[source]").to_hash.each { |k,v|
                          if v.kind_of? String
                              if v == "NULL"
                                  event.remove("[source]" + "[" + k + "]")
                              end
                          end
                      }
                  '
                }
    }
