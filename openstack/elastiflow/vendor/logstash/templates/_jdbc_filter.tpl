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
                    ["subnetpool_id", "varchar(36)" ]
                ]
                }
            ]

            local_lookups => [
                {
                id => "lookup_fields"
                query => "select domain, project, project_id, port from fips where floating_ip_address = ?"
                prepared_parameters => ["[client][domain]"]
                target => "data"
                }
            ]
            
            staging_directory => "/tmp/logstash/jdbc_static/import_data"
            loader_schedule => "* * * * *" # run loaders every minute
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
                add_field => {  cc_project_id => "%{[data][0][project_id]}" }
            }
            }
            # mutate {
            #   add_field => { cc_port => "%{[data][0][port]}"
            #                   cc_domain => "%{[data][0][domain]}" 
            #                   cc_project => "%{[data][0][project]}" 
            #                   cc_project_id => "%{[data][0][project_id]}" }
            #   remove_field => [ "data" ]
        }
        mutate {
                remove_field => [ "data" ]
        }
    }
