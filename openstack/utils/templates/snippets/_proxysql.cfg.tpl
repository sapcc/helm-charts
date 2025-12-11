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
    {{- $monitorGalera := false }}
    {{- /*
    Check that proxysql_monitor user exists in all DB instances
    Check that proxysql_monitor credentials are the same in all DB instances
    */}}
    {{- range $dbKey, $db := $dbs }}
        {{- if hasKey $db "pxc" }}
            {{- $monitorEnabled = true }}
            {{- $monitorUsername = "monitor" }}
            {{- $monitorPassword = $db.system_users.monitor.password }}
            {{- $monitorGalera = true }}
            {{- if (ne $monitorPassword $db.system_users.monitor.password) }}
                {{- fail (printf "system_users.monitor.password needs to be the same in %s as in other databases" $dbKey) }}
            {{- end }}
        {{- end }}
        {{- if and $db.users $db.users.proxysql_monitor }}
            {{- if not $monitorEnabled }}
                {{- $monitorEnabled = true }}
                {{- $monitorUsername = $db.users.proxysql_monitor.name }}
                {{- $monitorPassword = $db.users.proxysql_monitor.password }}
            {{- else if or (ne $monitorUsername $db.users.proxysql_monitor.name) (ne $monitorPassword $db.users.proxysql_monitor.password) }}
                {{- fail (printf "users.proxysql_monitor.password needs to be the same in %s as in other databases" $dbKey) }}
            {{- end }}
        {{- else if and $monitorEnabled (not $monitorGalera) }}
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
    max_transaction_time = {{ default 60000 .global.Values.proxysql.max_transaction_time }}
    default_query_timeout = {{ default 90000 .global.Values.proxysql.default_query_timeout }}
}

mysql_servers =
(
{{- range $index, $dbKey:= $.dbKeys }}
{{- /*
Example for Galera cluster:
    {
        address = "test-db-pxc-0.domain.svc.cluster.local"
        hostgroup = 11
        max_connections = 20
        weight = 101
    }
*/}}
    {{- $db := get $dbs $dbKey }}
    {{- if hasKey $db "pxc" }}
    {{- if gt (int $db.pxc.size) 7 }}
    {{- fail "The Galera cluster must not be bigger than 7 nodes" }}
    {{- end }}
    {{- range $i := until (int $db.pxc.size) }}
    {
        address = "{{ $db.name }}-db-pxc-{{ $i }}.{{ include "svc_fqdn" $.global }}"
        hostgroup = {{ add 1 (mul 10 (add1 $index)) }}
        max_connections = {{ $max_connections }}
        weight = {{ ternary 101 100 (eq $i 0) }}
    },
    {{- end }}
    {{- else }}
{{- /*
Example for MariaDB:
    {
        address = "test-mariadb.domain.svc.cluster.local"
        hostgroup = 11
        max_connections = 20
        weight = 101
    }
*/}}
    {
        address = "{{ $db.name }}-{{ $db.serviceSuffix }}.{{ include "svc_fqdn" $.global }}"
        hostgroup = {{ add 1 (mul 10 (add1 $index)) }}
        max_connections = {{ $max_connections }}
    },
    {{- end }}
{{- end }}
)

mysql_galera_hostgroups =
(
{{- range $index, $dbKey := $.dbKeys }}
    {{- $db := get $dbs $dbKey }}
    {{- if hasKey $db "pxc" }}
{{- /*
Example for Galera cluster:
    {
        writer_hostgroup=11
        backup_writer_hostgroup=12
        reader_hostgroup=13
        offline_hostgroup=199
        max_writers=1
        writer_is_also_reader=1
        max_transactions_behind=30
        active=1
        comment="test"
    }
*/}}
    {
      writer_hostgroup={{ add 1 (mul 10 (add1 $index)) }}
      backup_writer_hostgroup={{ add 2 (mul 10 (add1 $index)) }}
      reader_hostgroup={{ add 3 (mul 10 (add1 $index)) }}
      offline_hostgroup={{ add 99 (mul 100 (add1 $index)) }}
      max_writers=1
      writer_is_also_reader=1
      max_transactions_behind=30
      active=1
      comment="{{ $db.name }}"
    },
    {{- end }}
{{- end }}
)

mysql_users =
(
{{- $addedUsers := dict }}
{{- $addedUsernames := dict }}
{{- range $index, $dbKey := $.dbKeys }}
  {{- $db := get $.dbs $dbKey }}
  {{- range $userKey, $user := $db.users }}
    {{- $ignoreUsers := $.global.Values.proxysql.ignore_users | default list }}
    {{- $userName := include "resolve_secret" $user.name }}
    {{- if hasKey $addedUsernames $userName }}
        {{- fail (printf "Duplicate username '%s' found in database '%s' (already defined in another database)" $userName $dbKey) }}
    {{- end }}
    {{- if hasKey $addedUsers $userKey }}
        {{- fail (printf "Duplicate user key '%s' found in database '%s' (already defined in another database)" $userKey $dbKey) }}
    {{- end }}
    {{- if or
        (not $user.password)
        (eq $userKey "proxysql_monitor")
        (and (hasKey $user "enabled") (eq (typeOf $user.enabled) "bool") (eq $user.enabled false))
        (has $userKey $ignoreUsers)
        (has $userName $ignoreUsers)
    }}
    {{- /* skip user */}}
    {{- else }}
    {{- $_ := set $addedUsers $userKey true }}
    {{- $_ := set $addedUsernames $userName true }}
    {
        username = "{{ include "resolve_secret" $user.name | required (print "user name needs to be set for " $dbKey " and user " $userKey) }}"
        password = "{{ include "resolve_secret" $user.password | required (print "password needs to be set for " $dbKey " and user " $userKey)  }}"
        default_hostgroup = {{ add 1 (mul 10 (add1 $index)) }}
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
