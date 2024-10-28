{{- define "utils.snippets.set_proxysql_config" }}
  {{- $dbs := .dbs }}
  {{- $dbKeys := .dbKeys }}
  {{- $max_connections := .max_connections }}
admin_variables =
{
    restapi_enabled = true
    restapi_port = {{ default 6070 .global.Values.proxysql.restapi_port }}
    prometheus_memory_metrics_interval = {{ default 61 .global.Values.proxysql.prometheus_memory_metrics_interval }}
}

mysql_variables =
{
    interfaces = "127.0.0.1:3306;/run/proxysql/mysql.sock"
    {{- $monitorEnabled := false }}
    {{- $monitorUsername := "" }}
    {{- $monitorPassword := "" }}
    {{- /*
    Check that proxysql_monitor user exists in all DB instances
    Check that proxysql_monitor credentials are the same in all DB instances
    */}}
    {{- range $dbKey, $db := $dbs }}
        {{- if and $db.users $db.users.proxysql_monitor }}
            {{- if not $monitorEnabled }}
                {{- $monitorEnabled = true }}
                {{- $monitorUsername = $db.users.proxysql_monitor.name }}
                {{- $monitorPassword = $db.users.proxysql_monitor.password }}
            {{- else if or (ne $monitorUsername $db.users.proxysql_monitor.name) (ne $monitorPassword $db.users.proxysql_monitor.password) }}
                {{- fail (printf "users.proxysql_monitor.password needs to be the same in %s as in other databases" $dbKey) }}
            {{- end }}
        {{- else if $monitorEnabled }}
            {{- fail (printf "users.proxysql_monitor.password is missing in database %s but present in others" $dbKey) }}
        {{- end }}
    {{- end }}
    {{- if not $monitorEnabled }}
    monitor_enabled = false
    {{- else }}
    monitor_enabled = true
    monitor_username = "{{ include "resolve_secret" $monitorUsername | required "db.users.proxysql_monitor.name is required!" }}"
    monitor_password = "{{ include "resolve_secret" $monitorPassword | required "db.users.proxysql_monitor.password is required!" }}"
    {{- end }}
    connect_retries_on_failure = {{ default 1000 .global.Values.proxysql.connect_retries_on_failure }}
    connect_retries_delay = {{ default 100 .global.Values.proxysql.connect_retries_delay }} {{- /* The default is 1ms, and that means we will run through the retries on failure in no time */}}
    connect_timeout_server_max = {{ default 100000 .global.Values.proxysql.connect_timeout_server_max }}
}

mysql_servers =
(
{{- range $index, $dbKey:= $.dbKeys }}
  {{- $db := get $dbs $dbKey }}
    {
        address = "{{ $db.name }}-{{ $db.serviceSuffix }}.{{ include "svc_fqdn" $.global }}"
        hostgroup = {{ $index }}
        max_connections = {{ $max_connections }}
    },
{{- end }}
)

mysql_users =
(
{{- range $index, $dbKey := $.dbKeys }}
  {{- $db := get $.dbs $dbKey }}
  {{- range $userKey, $user := $db.users }}
    {{- if ne $userKey "proxysql_monitor"  }}
    {
        username = "{{ include "resolve_secret" $user.name | required (print "user name needs to be set for " $dbKey " and user " $userKey) }}"
        password = "{{ include "resolve_secret" $user.password | required (print "password needs to be set for " $dbKey " and user " $userKey)  }}"
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
