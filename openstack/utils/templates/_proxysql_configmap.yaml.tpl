{{- define "proxysql_configmap" }}
    {{- $envAll := . }}
    {{- if .Values.proxysql -}}
        {{- if .Values.proxysql.mode -}}
{{- $max_pool_size := coalesce .Values.max_pool_size .Values.global.max_pool_size 50 }}
{{- $max_overflow := coalesce .Values.max_overflow .Values.global.max_overflow 5 }}
{{- $max_connections := .Values.proxysql.max_connnections | default (add $max_pool_size $max_overflow) }}

{{- $dbs := dict }}
{{- range $d := $envAll.Chart.Dependencies }}
    {{- if and $d.Enabled (hasPrefix "mariadb" $d.Name)}}
        {{- $_ := set $dbs $d.Name (get $envAll.Values $d.Name) }}
    {{- end }}
{{- end }}
{{- $dbKeys := keys $dbs | sortAlpha }}
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
        {{- if not .Values.mariadb.users }}
        monitor_enabled = false
        {{- else if not .Values.mariadb.users.proxysql_monitor }}
        monitor_enabled = false
        {{- else }}
            {{- /* Validate equality of the monitor user in all mariadb instance in the chart */}}
            {{- range $dbKey, $db := $dbs }}
                {{- if not $db.users }}
                    fail (print ".Values. " $dbKey ".users needs to be set")
                {{- else if not $db.users.proxysql_monitor }}
                    fail (print ".Values. " $dbKey ".users.proxysql_monitor needs to be set")
                {{- else if not eq .Values.mariadb.users.proxysql_monitor.name $db.users.proxysql_monitor.name }}
                    fail (print ".Values. " $dbKey ".users.proxysql_monitor.name needs to be equal to .Values.mariadb.users.proxysql_monitor.name")
                {{- else if not eq .Values.mariadb.users.proxysql_monitor.password $db.users.proxysql_monitor.password }}
                    fail (print ".Values. " $dbKey ".users.proxysql_monitor.password needs to be equal to .Values.mariadb.users.proxysql_monitor.password")
                {{- end }}
            {{- end }}
        monitor_enabled = true
        monitor_username = "{{ .Values.mariadb.users.proxysql_monitor.name | required ".Values.mariadb.users.proxysql_monitor.name is required!" }}"
        monitor_password = "{{ .Values.mariadb.users.proxysql_monitor.password | required ".Values.mariadb.users.proxysql_monitor.password is required!" }}"
        {{- end }}
        connect_retries_on_failure = {{ default 1000 .Values.proxysql.connect_retries_on_failure }}
        connect_retries_delay = {{ default 100 .Values.proxysql.connect_retries_delay }} {{- /* The default is 1ms, and that means we will run through the retries on failure in no time */}}
        connect_timeout_server_max = {{ default 100000 .Values.proxysql.connect_timeout_server_max }}
    }

    mysql_servers =
    (
{{- range $index, $dbKey:= $dbKeys }}
    {{- $db := get $dbs $dbKey }}
        {
            address = "{{ $db.name }}-mariadb.{{ include "svc_fqdn" $envAll }}"
            hostgroup = {{ $index }}
            max_connections = {{ $max_connections }}
        },
{{- end }}
    )

    mysql_users =
    (
{{- range $index, $dbKey := $dbKeys }}
    {{- $db := get $dbs $dbKey }}
    {{- range $userKey, $user := $db.users }}
        {{- if ne $userKey "proxysql_monitor"  }}
        {
            username = "{{ $user.name | required (print "user name needs to be set for " $dbKey " and user " $userKey)  }}"
            password = "{{ $user.password | required "password needs to be set for all extra dbs" }}"
            default_hostgroup = {{ $index }}
        },
        {{- end }}
    {{- end }}
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
