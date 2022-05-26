{{- define "proxy_sql_configmap" }}
    {{ $dbs := index . 1 }}
    {{ $dbKeys := keys $dbs | sortAlpha }}
    {{ $envAll := index . 0 }}
    {{ with $envAll }}
        {{- if .Values.proxysql -}}
            {{- if .Values.proxysql.mode -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-proxysql-etc
  labels:
    system: openstack
    type: configuration
    component: database
data:
  proxysql.cnf: |
    admin_variables =
    {
        restapi_enabled = true
        restapi_port = {{ default 6070 .Values.proxysql.restapi_port }}
        prometheus_memory_metrics_interval = {{ default 61 .Values.proxysql.prometheus_memory_metrics_interval }}
    }

    mysql_variables =
    {
        interfaces = "127.0.0.1:3306;/run/proxysql/mysql.sock"
        monitor_username = "root"
        monitor_password = "{{ .Values.mariadb.root_password | required ".Values.mariadb.root_password is required!" }}"
        monitor_enabled = {{ if $dbs -}} false {{- else -}} true {{- end }}
        connect_retries_on_failure = {{ default 1000 .Values.proxysql.connect_retries_on_failure }}
        connect_retries_delay = {{ default 100 .Values.proxysql.connect_retries_delay }} {{- /* The default is 1ms, and that means we will run through the retries on failure in no time */}}
        connect_timeout_server_max = {{ default 100000 .Values.proxysql.connect_timeout_server_max }}
    }

    mysql_servers =
    (
        {
            {{- $max_pool_size := coalesce .Values.max_pool_size .Values.global.max_pool_size 50 }}
            {{- $max_overflow := coalesce .Values.max_overflow .Values.global.max_overflow 5 }}
            {{- $max_connections := .Values.proxysql.max_connnections | default (add $max_pool_size $max_overflow) }}
            {{- $address := include "db_host_mysql" . }}
            {{- $host_groups := dict $address 0 }}
            address = "{{ $address }}.{{ include "svc_fqdn" $envAll }}"
            hostgroup = 0
            max_connections = {{ $max_connections }}
        },
        {{- range $key:= $dbKeys }}
            {{- $entry := get $dbs $key }}
            {{- $address := get $entry "host" }}
            {{- if hasKey $host_groups $address }}
                {{- /* Nothing to be done */}}
            {{- else }}
                {{- $index := len $host_groups }}
                {{- $_ := set $host_groups $address $index }}
        {
            address = "{{ $address }}.{{ include "svc_fqdn" $envAll }}"
            hostgroup = {{ $index }}
            max_connections = {{ $max_connections }}
        },
            {{- end }}
        {{- end }}
    )

    mysql_users =
    (
        {
            username = "{{ coalesce .Values.dbUser .Values.global.dbUser "root" }}"
            password = "{{ coalesce .Values.dbPassword .Values.global.dbPassword .Values.mariadb.root_password | required ".Values.mariadb.root_password is required!"}}"
            default_hostgroup = 0
            default_schema = "{{ coalesce .Values.dbName .Values.db_name }}"
        },
        {{- range $key:= $dbKeys }}
        {
            {{- $entry := get $dbs $key }}
            {{- $address := get $entry "host" }}
            username = "{{ get $entry "user" | required "user needs to be set for all extra dbs"  }}"
            password = "{{ get $entry "password" | required "password needs to be set for all extra dbs" }}"
            default_hostgroup = {{ get $host_groups $address }}
            default_schema = "{{ get $entry "schema" }}"
        },
        {{- end }}
    )

    mysql_query_rules =
    (
        {
            rule_id = 0,
            active = 1,
            apply = 1,
            cache_ttl = 3600000,
            match_pattern = "^SELECT 1$",
        },
    )
            {{- end }}
        {{- end }}
    {{- end }}
{{- end }}
