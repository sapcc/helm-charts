filter {
        if [client][domain] and [destination][domain] {
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
                  id => "lookup_client"
                  query => "select domain, project, project_id, port, network, network_id, subnet, subnet_id, subnetpool, subnetpool_id, router, router_id, instance_id, instance_name, host, availability_zone from fips where floating_ip_address = ?"
                  prepared_parameters => ["[client][domain]"]
                  target => "client"
                  },
                  {
                  id => "lookup_destination"
                  query => "select domain, project, project_id, port, network, network_id, subnet, subnet_id, subnetpool, subnetpool_id, router, router_id, instance_id, instance_name, host, availability_zone from fips where floating_ip_address = ?"
                  prepared_parameters => ["[destination][domain]"]
                  target => "destination"
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

          if [client] and [client][0] {
              if [client][0][port] and [client][0][port] != "NULL" {
                  mutate {
                      add_field => { "[client][cc_port]" => "%{[client][0][port]}" }
                  }
              }
              if [client][0][domain] and [client][0][domain] != "NULL" {
                  mutate {
                      add_field => { "[client][cc_domain]" => "%{[client][0][domain]}" }
                  }
              }
              if [client][0][project] and [client][0][project] != "NULL" { 
                  mutate {
                      add_field => { "[client][cc_project]" => "%{[client][0][project]}" }
                  }
              }
              if [client][0][project_id] and [client][0][project_id] != "NULL" { 
                  mutate {
                      add_field => { "[client][cc_project_id]" => "%{[client][0][project_id]}" }
                  }
              }
              if [client][0][network] and [client][0][network] != "NULL" {
                  mutate {
                      add_field => {  "[client][cc_network]" => "%{[client][0][network]}" }
                  }
              }
              if [client][0][network_id] and [client][0][network_id] != "NULL" {
                  mutate {
                      add_field => {  "[client][cc_network_id]" => "%{[client][0][network_id]}" }
                  }
              }
               if [client][0][subnet] and [client][0][subnet] != "NULL" {
                  mutate {
                      add_field => {  "[client][cc_subnet]" => "%{[client][0][subnet]}" }
                  }
              }
               if [client][0][subnet_id] and [client][0][subnet_id] != "NULL" {
                  mutate {
                      add_field => {  "[client][cc_subnet_id]" => "%{[client][0][subnet_id]}" }
                  }
              }
              if [client][0][subnetpool] and [client][0][subnetpool] != "NULL" {
                  mutate {
                      add_field => {  "[client][cc_subnetpool]" => "%{[client][0][subnetpool]}" }
                  }
              }
              if [client][0][subnetpool_id] and [client][0][subnetpool_id] != "NULL" {
                  mutate {
                      add_field => {  "[client][cc_subnetpool_id]" => "%{[client][0][subnetpool_id]}" }
                  }
              }
              if [client][0][router] and [client][0][router] != "NULL" {
                  mutate {
                      add_field => {  "[client][cc_router]" => "%{[client][0][router]}" }
                  }
              }
              if [client][0][router_id] and [client][0][router_id] != "NULL" {
                  mutate {
                      add_field => {  "[client][cc_router_id]" => "%{[client][0][router_id]}" }
                  }
              }
              if [client][0][instance_id] and [client][0][instance_id] != "NULL" {
                  mutate {
                      add_field => {  "[client][cc_instance_id]" => "%{[client][0][instance_id]}" }
                  }
              }
              if [client][0][instance_name] and [client][0][instance_name] != "NULL" {
                  mutate {
                      add_field => {  "[client][cc_instance_name]" => "%{[client][0][instance_name]}" }
                  }
              }
              if [client][0][host] and [client][0][host] != "NULL" {
                  mutate {
                      add_field => {  "[client][cc_host]" => "%{[client][0][host]}" }
                  }
              }
              if [client][0][availability_zone] and [client][0][availability_zone] != "NULL" {
                  mutate {
                      add_field => {  "[client][cc_availability_zone]" => "%{[client][0][availability_zone]}" }
                  }
              }
          }
          mutate {
                  remove_field => [ "client" ]
        }

          if [destination] and [destination][0] {
              if [destination][0][port] and [destination][0][port] != "NULL" {
                  mutate {
                      add_field => { "[destination][cc_port]" => "%{[destination][0][port]}" }
                  }
              }
              if [destination][0][domain] and [destination][0][domain] != "NULL" {
                  mutate {
                      add_field => { "[destination][cc_domain]" => "%{[destination][0][domain]}" }
                  }
              }
              if [destination][0][project] and [destination][0][project] != "NULL" { 
                  mutate {
                      add_field => { "[destination][cc_project]" => "%{[destination][0][project]}" }
                  }
              }
              if [destination][0][project_id] and [destination][0][project_id] != "NULL" { 
                  mutate {
                      add_field => { "[destination][cc_project_id]" => "%{[destination][0][project_id]}" }
                  }
              }
              if [destination][0][network] and [destination][0][network] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_network]" => "%{[destination][0][network]}" }
                  }
              }
              if [destination][0][network_id] and [destination][0][network_id] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_network_id]" => "%{[destination][0][network_id]}" }
                  }
              }
                if [destination][0][subnet] and [destination][0][subnet] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_subnet]" => "%{[destination][0][subnet]}" }
                  }
              }
                if [destination][0][subnet_id] and [destination][0][subnet_id] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_subnet_id]" => "%{[destination][0][subnet_id]}" }
                  }
              }
              if [destination][0][subnetpool] and [destination][0][subnetpool] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_subnetpool]" => "%{[destination][0][subnetpool]}" }
                  }
              }
              if [destination][0][subnetpool_id] and [destination][0][subnetpool_id] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_subnetpool_id]" => "%{[destination][0][subnetpool_id]}" }
                  }
              }
              if [destination][0][router] and [destination][0][router] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_router]" => "%{[destination][0][router]}" }
                  }
              }
              if [destination][0][router_id] and [destination][0][router_id] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_router_id]" => "%{[destination][0][router_id]}" }
                  }
              }
              if [destination][0][instance_id] and [destination][0][instance_id] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_instance_id]" => "%{[destination][0][instance_id]}" }
                  }
              }
              if [destination][0][instance_name] and [destination][0][instance_name] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_instance_name]" => "%{[destination][0][instance_name]}" }
                  }
              }
              if [destination][0][host] and [destination][0][host] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_host]" => "%{[destination][0][host]}" }
                  }
              }
              if [destination][0][availability_zone] and [destination][0][availability_zone] != "NULL" {
                  mutate {
                      add_field => {  "[destination][cc_availability_zone]" => "%{[destination][0][availability_zone]}" }
                  }
              }
          }
          mutate {
                  remove_field => [ "destination" ]
        }
    }
