filter {
        if [source][domain] and [destination][domain] {
            jdbc_static {
              id => "jdbc"
              loaders =>[
                  {
                  id => "datahubdb"
                  query => "select * from openstack_ips"
                  local_table => "fips"
                  }
              ]

              local_db_objects => [
                  {
                  name => "fips"
                  index_columns => ["floating_ip_address"]
                  columns => [
                      ["floating_ip_address", "varchar(64)"],
                      ["floating_ip_id", "varchar(36)"],                    
                      ["port", "varchar(36)" ],
                      ["project", "varchar(64)" ],
                      ["project_id", "varchar(64)" ],
                      ["domain", "varchar(64)" ],
                      ["network", "varchar(255)"],
                      ["network_id", "varchar(36)" ],
                      ["subnet", "varchar(255)"],
                      ["subnet_id", "varchar(36)" ],
                      ["subnetpool", "varchar(255)"],
                      ["subnetpool_id", "varchar(36)" ],
                      ["router_id", "varchar(36)" ],
                      ["router", "varchar(255)"],
                      ["instance_id", "varchar(255)"],
                      ["owner", "varchar(255)"],
                      ["instance_name", "varchar(255)"],
                      ["host", "varchar(255)"],
                      ["availability_zone", "varchar(255)"]
                  ]
                  }
              ]

              local_lookups => [
                  {
                  id => "lookup_source"
                  query => "select domain, project, project_id, port, network, network_id, subnet, subnet_id, subnetpool, subnetpool_id, router, router_id, instance_id, instance_name, host, availability_zone from fips where floating_ip_address = ?"
                  prepared_parameters => ["[source][domain]"]
                  target => "source_data"
                  },
                  {
                  id => "lookup_destination"
                  query => "select domain, project, project_id, port, network, network_id, subnet, subnet_id, subnetpool, subnetpool_id, router, router_id, instance_id, instance_name, host, availability_zone from fips where floating_ip_address = ?"
                  prepared_parameters => ["[destination][domain]"]
                  target => "destination_data"
                  }
              ]
            
              staging_directory => "/tmp/logstash/jdbc_static/import_data"
              loader_schedule => "{{ .Values.jdbc.schedule }}"
              jdbc_user => "{{ .Values.global.datahub.user }}"
              jdbc_password => "${DATAHUB_PASSWORD}"
              jdbc_driver_class => "com.mysql.cj.jdbc.Driver"
              jdbc_driver_library => ""
              jdbc_connection_string => "jdbc:mysql://{{ .Values.jdbc.service }}.{{ .Values.jdbc.namespace }}:3306/{{ .Values.jdbc.db }}"
              }
          }

          if [source_data] and [source_data][0] {
                  mutate {
                      add_field => { "[source][cc_port]" => "%{[source_data][0][port]}"
                                     "cc_port" => "%{[source_data][0][port]}"
                                     "[source][cc_domain]" => "%{[source_data][0][domain]}"
                                     "cc_domain" => "%{[source_data][0][domain]}"
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
                                     "[source][cc_instance_name]" => "%{[source_data][0][instance_name]}"
                                     "cc_instance_name" => "%{[source_data][0][instance_name]}"
                                     "[source][cc_host]" => "%{[source_data][0][host]}"
                                     "cc_host" => "%{[source_data][0][host]}"
                                     "[source][cc_availability_zone]" => "%{[source_data][0][availability_zone]}"
                                     "cc_availability_zone" => "%{[source_data][0][availability_zone]}"
                  }
              }
          }
          mutate {
                  remove_field => [ "source_data" ]
        }

          if [destination_data] and [destination_data][0] {
                  mutate {
                      add_field => {  "[destination][cc_port]" => "%{[destination_data][0][port]}"
                                     "cc_port" => "%{[destination_data][0][port]}"
                                     "[destination][cc_domain]" => "%{[destination_data][0][domain]}"
                                     "cc_domain" => "%{[destination_data][0][domain]}"
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
                                     "[destination][cc_instance_name]" => "%{[destination_data][0][instance_name]}"
                                     "cc_instance_name" => "%{[destination_data][0][instance_name]}"
                                     "[destination][cc_host]" => "%{[destination_data][0][host]}"
                                     "cc_host" => "%{[destination_data][0][host]}"
                                     "[destination][cc_availability_zone]" => "%{[destination_data][0][availability_zone]}"
                                     "cc_availability_zone" => "%{[destination_data][0][availability_zone]}"
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
