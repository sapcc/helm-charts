filter {
        if [client][domain] {
            jdbc_static {
            loaders =>[
                {
                id => "datahubdb"
                query => "select * from test"
                local_table => "fips"
                }
            ]

            local_db_objects => [
                {
                name => "fips"
                index_columns => ["floating_ip_address"]
                columns => [
                    ["floating_ip_address", "varchar(64)"],
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
                    ["router", "varchar(255)"],
                    ["router_id", "varchar(36)" ]
                ]
                }
            ]

            local_lookups => [
                {
                id => "lookup_fields"
                query => "select domain, project, project_id, port, network, network_id, subnet, subnet_id, subnetpool, subnetpool_id, router, router_id from fips where floating_ip_address = ?"
                prepared_parameters => ["[client][domain]"]
                target => "data"
                }
            ]
            
            staging_directory => "/tmp/logstash/jdbc_static/import_data"
            loader_schedule => "0 0/2 * * *" # run loaders every minute
            jdbc_user => "{{ .Values.jdbc.user }}"
            jdbc_password => "{{ .Values.jdbc.password }}"
            jdbc_driver_class => "com.mysql.cj.jdbc.Driver"
            jdbc_driver_library => ""
            jdbc_connection_string => "jdbc:mysql://{{ .Values.jdbc.service }}.{{ .Values.jdbc.namespace }}:3306/{{ .Values.jdbc.db }}"
            }
        }

        if [data] and [data][0] {
            if [data][0][port] {
            mutate {
                add_field => { cc_port => "%{[data][0][port]}" }
            }
            }
            if [data][0][domain] {
            mutate {
                add_field => { cc_domain => "%{[data][0][domain]}" }
            }
            }
            if [data][0][project] { 
            mutate {
                add_field => { cc_project => "%{[data][0][project]}" }
            }
            }
            if [data][0][project_id] { 
            mutate {
                add_field => { cc_project_id => "%{[data][0][project_id]}" }
            }
            }
            if [data][0][network] {
            mutate {
                add_field => {  cc_network => "%{[data][0][network]}" }
            }
            }
            if [data][0][network_id] {
            mutate {
                add_field => {  cc_network_id => "%{[data][0][network_id]}" }
            }
            }
             if [data][0][subnet] {
            mutate {
                add_field => {  cc_subnet => "%{[data][0][subnet]}" }
            }
            }
             if [data][0][subnet_id] {
            mutate {
                add_field => {  cc_subnet_id => "%{[data][0][subnet_id]}" }
            }
            }
            if [data][0][subnetpool] {
            mutate {
                add_field => {  cc_subnetpool => "%{[data][0][subnetpool]}" }
            }
            }
            if [data][0][subnetpool_id] {
            mutate {
                add_field => {  cc_subnetpool_id => "%{[data][0][subnetpool_id]}" }
            }
            }
            if [data][0][router] {
            mutate {
                add_field => {  cc_router => "%{[data][0][router]}" }
            }
            }
            if [data][0][router_id] {
            mutate {
                add_field => {  cc_router_id => "%{[data][0][router_id]}" }
            }
            }
        }
        mutate {
                remove_field => [ "data" ]
        }
    }
