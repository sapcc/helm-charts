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
              if [source_data][0][port] and [source_data][0][port] != "NULL" {
                  mutate {
                      add_field => { "[source][cc_port]" => "%{[source_data][0][port]}" 
                                     "cc_port" => "%{[source_data][0][port]}"}
                  }
              }
              if [source_data][0][domain] and [source_data][0][domain] != "NULL" {
                  mutate {
                      add_field => { "[source][cc_domain]" => "%{[source_data][0][domain]}"
                                     "cc_domain" => "%{[source_data][0][domain]}" }
                  }
              }
              if [source_data][0][project] and [source_data][0][project] != "NULL" { 
                  mutate {
                      add_field => { "[source][cc_project]" => "%{[source_data][0][project]}"
                                     "cc_project" => "%{[source_data][0][project]}" }
                  }
              }
              if [source_data][0][project_id] and [source_data][0][project_id] != "NULL" { 
                  mutate {
                      add_field => { "[source][cc_project_id]" => "%{[source_data][0][project_id]}"
                                     "cc_project_id" => "%{[source_data][0][project_id]}" }
                  }
              }
              if [source_data][0][network] and [source_data][0][network] != "NULL" {
                  mutate {
                      add_field => {  "[source][cc_network]" => "%{[source_data][0][network]}"
                                      "cc_network" => "%{[source_data][0][network]}" }
                  }
              }
              if [source_data][0][network_id] and [source_data][0][network_id] != "NULL" {
                  mutate {
                      add_field => {  "[source][cc_network_id]" => "%{[source_data][0][network_id]}"
                                      "cc_network_id" => "%{[source_data][0][network_id]}" }
                  }
              }
               if [source_data][0][subnet] and [source_data][0][subnet] != "NULL" {
                  mutate {
                      add_field => {  "[source][cc_subnet]" => "%{[source_data][0][subnet]}"
                                      "cc_subnet" => "%{[source_data][0][subnet]}" }
                  }
              }
               if [source_data][0][subnet_id] and [source_data][0][subnet_id] != "NULL" {
                  mutate {
                      add_field => {  "[source][cc_subnet_id]" => "%{[source_data][0][subnet_id]}"
                                      "cc_subnet_id" => "%{[source_data][0][subnet_id]}" }
                  }
              }
              if [source_data][0][subnetpool] and [source_data][0][subnetpool] != "NULL" {
                  mutate {
                      add_field => {  "[source][cc_subnetpool]" => "%{[source_data][0][subnetpool]}"
                                      "cc_subnetpool" => "%{[source_data][0][subnetpool]}" }
                  }
              }
              if [source_data][0][subnetpool_id] and [source_data][0][subnetpool_id] != "NULL" {
                  mutate {
                      add_field => {  "[source][cc_subnetpool_id]" => "%{[source_data][0][subnetpool_id]}"
                                      "cc_subnetpool_id" => "%{[source_data][0][subnetpool_id]}" }
                  }
              }
              if [source_data][0][router] and [source_data][0][router] != "NULL" {
                  mutate {
                      add_field => {  "[source][cc_router]" => "%{[source_data][0][router]}"
                                      "cc_router" => "%{[source_data][0][router]}" }
                  }
              }
              if [source_data][0][router_id] and [source_data][0][router_id] != "NULL" {
                  mutate {
                      add_field => {  "[source][cc_router_id]" => "%{[source_data][0][router_id]}"
                                      "cc_router_id" => "%{[source_data][0][router_id]}" }
                  }
              }
              if [source_data][0][instance_id] and [source_data][0][instance_id] != "NULL" {
                  mutate {
                      add_field => {  "[source][cc_instance_id]" => "%{[source_data][0][instance_id]}"
                                      "cc_instance_id" => "%{[source_data][0][instance_id]}" }
                  }
              }
              if [source_data][0][instance_name] and [source_data][0][instance_name] != "NULL" {
                  mutate {
                      add_field => {  "[source][cc_instance_name]" => "%{[source_data][0][instance_name]}"
                                      "cc_instance_name" => "%{[source_data][0][instance_name]}" }
                  }
              }
              if [source_data][0][host] and [source_data][0][host] != "NULL" {
                  mutate {
                      add_field => {  "[source][cc_host]" => "%{[source_data][0][host]}"
                                      "cc_host" => "%{[source_data][0][host]}" }
                  }
              }
              if [source_data][0][availability_zone] and [source_data][0][availability_zone] != "NULL" {
                  mutate {
                      add_field => {  "[source][cc_availability_zone]" => "%{[source_data][0][availability_zone]}"
                                      "cc_availability_zone" => "%{[source_data][0][availability_zone]}" }
                  }
              }
          }
          mutate {
                  remove_field => [ "source_data" ]
        }

          if [destination_data] and [destination_data][0] {
              if [destination_data][0][port] and [destination_data][0][port] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_port]" => "%{[destination_data][0][port]}"
                                      "cc_port" => "%{[destination_data][0][port]}" }
                  }
              }
              if [destination_data][0][domain] and [destination_data][0][domain] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_domain]" => "%{[destination_data][0][domain]}"
                                      "cc_domain" => "%{[destination_data][0][domain]}" }
                  }
              }
              if [destination_data][0][project] and [destination_data][0][project] != "NULL" { 
                  mutate {
                      add_field => {  "[destination][cc_project]" => "%{[destination_data][0][project]}"
                                      "cc_project" => "%{[destination_data][0][project]}" }
                  }
              }
              if [destination_data][0][project_id] and [destination_data][0][project_id] != "NULL" { 
                  mutate {
                      add_field => {  "[destination][cc_project_id]" => "%{[destination_data][0][project_id]}"
                                      "cc_project_id" => "%{[destination_data][0][project_id]}" }
                  }
              }
              if [destination_data][0][network] and [destination_data][0][network] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_network]" => "%{[destination_data][0][network]}"
                                      "cc_network" => "%{[destination_data][0][network]}" }
                  }
              }
              if [destination_data][0][network_id] and [destination_data][0][network_id] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_network_id]" => "%{[destination_data][0][network_id]}"
                                      "cc_network_id" => "%{[destination_data][0][network_id]}" }
                  }
              }
                if [destination_data][0][subnet] and [destination_data][0][subnet] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_subnet]" => "%{[destination_data][0][subnet]}"
                                      "cc_subnet" => "%{[destination_data][0][subnet]}" }
                  }
              }
                if [destination_data][0][subnet_id] and [destination_data][0][subnet_id] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_subnet_id]" => "%{[destination_data][0][subnet_id]}"
                                      "cc_subnet_id" => "%{[destination_data][0][subnet_id]}" }
                  }
              }
              if [destination_data][0][subnetpool] and [destination_data][0][subnetpool] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_subnetpool]" => "%{[destination_data][0][subnetpool]}"
                                      "cc_subnetpool" => "%{[destination_data][0][subnetpool]}" }
                  }
              }
              if [destination_data][0][subnetpool_id] and [destination_data][0][subnetpool_id] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_subnetpool_id]" => "%{[destination_data][0][subnetpool_id]}"
                                      "cc_subnetpool_id" => "%{[destination_data][0][subnetpool_id]}" }
                  }
              }
              if [destination_data][0][router] and [destination_data][0][router] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_router]" => "%{[destination_data][0][router]}"
                                      "cc_router" => "%{[destination_data][0][router]}" }
                  }
              }
              if [destination_data][0][router_id] and [destination_data][0][router_id] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_router_id]" => "%{[destination_data][0][router_id]}"
                                      "cc_router_id" => "%{[destination_data][0][router_id]}" }
                  }
              }
              if [destination_data][0][instance_id] and [destination_data][0][instance_id] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_instance_id]" => "%{[destination_data][0][instance_id]}"
                                      "cc_instance_id" => "%{[destination_data][0][instance_id]}" }
                  }
              }
              if [destination_data][0][instance_name] and [destination_data][0][instance_name] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_instance_name]" => "%{[destination_data][0][instance_name]}"
                                      "cc_instance_name" => "%{[destination_data][0][instance_name]}" }
                  }
              }
              if [destination_data][0][host] and [destination_data][0][host] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_host]" => "%{[destination_data][0][host]}"
                                      "cc_host" => "%{[destination_data][0][host]}" }
                  }
              }
              if [destination_data][0][availability_zone] and [destination_data][0][availability_zone] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_availability_zone]" => "%{[destination_data][0][availability_zone]}"
                                      "cc_availability_zone" => "%{[destination_data][0][availability_zone]}" }
                  }
              }
          }
          mutate {
                  remove_field => [ "destination_data" ]
        }
    }
