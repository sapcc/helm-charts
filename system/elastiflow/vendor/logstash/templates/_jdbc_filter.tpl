filter {
        if [client][domain] {
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
                  id => "lookup_fields"
                  query => "select domain, project, project_id, port, network, network_id, subnet, subnet_id, subnetpool, subnetpool_id, router, router_id, instance_id, instance_name, host, availability_zone from fips where floating_ip_address = ?"
                  prepared_parameters => ["[client][domain]"]
                  target => "data"
                  }
              ]
            
              staging_directory => "/tmp/logstash/jdbc_static/import_data"
              loader_schedule => "{{ .Values.jdbc.schedule }}"
              jdbc_user => "{{ .Values.global.datahub.user }}"
              jdbc_password => ${DATAHUB_PASSWORD}
              jdbc_driver_class => "com.mysql.cj.jdbc.Driver"
              jdbc_driver_library => ""
              jdbc_connection_string => "jdbc:mysql://{{ .Values.jdbc.service }}.{{ .Values.jdbc.namespace }}:3306/{{ .Values.jdbc.db }}"
              }
          }

          if [data] and [data][0] {
              if [data][0][port] and [data][0][port] != "NULL" {
                  mutate {
                      add_field => { cc_port => "%{[data][0][port]}" }
                  }
              }
              if [data][0][domain] and [data][0][domain] != "NULL" {
                  mutate {
                      add_field => { cc_domain => "%{[data][0][domain]}" }
                  }
              }
              if [data][0][project] and [data][0][project] != "NULL" { 
                  mutate {
                      add_field => { cc_project => "%{[data][0][project]}" }
                  }
              }
              if [data][0][project_id] and [data][0][project_id] != "NULL" { 
                  mutate {
                      add_field => { cc_project_id => "%{[data][0][project_id]}" }
                  }
              }
              if [data][0][network] and [data][0][network] != "NULL" {
                  mutate {
                      add_field => {  cc_network => "%{[data][0][network]}" }
                  }
              }
              if [data][0][network_id] and [data][0][network_id] != "NULL" {
                  mutate {
                      add_field => {  cc_network_id => "%{[data][0][network_id]}" }
                  }
              }
               if [data][0][subnet] and [data][0][subnet] != "NULL" {
                  mutate {
                      add_field => {  cc_subnet => "%{[data][0][subnet]}" }
                  }
              }
               if [data][0][subnet_id] and [data][0][subnet_id] != "NULL" {
                  mutate {
                      add_field => {  cc_subnet_id => "%{[data][0][subnet_id]}" }
                  }
              }
              if [data][0][subnetpool] and [data][0][subnetpool] != "NULL" {
                  mutate {
                      add_field => {  cc_subnetpool => "%{[data][0][subnetpool]}" }
                  }
              }
              if [data][0][subnetpool_id] and [data][0][subnetpool_id] != "NULL" {
                  mutate {
                      add_field => {  cc_subnetpool_id => "%{[data][0][subnetpool_id]}" }
                  }
              }
              if [data][0][router] and [data][0][router] != "NULL" {
                  mutate {
                      add_field => {  cc_router => "%{[data][0][router]}" }
                  }
              }
              if [data][0][router_id] and [data][0][router_id] != "NULL" {
                  mutate {
                      add_field => {  cc_router_id => "%{[data][0][router_id]}" }
                  }
              }
              if [data][0][instance_id] and [data][0][instance_id] != "NULL" {
                  mutate {
                      add_field => {  cc_instance_id => "%{[data][0][instance_id]}" }
                  }
              }
              if [data][0][instance_name] and [data][0][instance_name] != "NULL" {
                  mutate {
                      add_field => {  cc_instance_name => "%{[data][0][instance_name]}" }
                  }
              }
              if [data][0][host] and [data][0][host] != "NULL" {
                  mutate {
                      add_field => {  cc_host => "%{[data][0][host]}" }
                  }
              }
              if [data][0][availability_zone] and [data][0][availability_zone] != "NULL" {
                  mutate {
                      add_field => {  cc_availability_zone => "%{[data][0][availability_zone]}" }
                  }
              }
          }
          mutate {
                  remove_field => [ "data" ]
        }
    }
