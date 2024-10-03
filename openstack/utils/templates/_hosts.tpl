{{- define "host_fqdn" -}}
{{ .Values.global.region }}.{{ .Values.global.tld }}
{{- end }}

{{- define "svc_fqdn" -}}
{{ .Release.Namespace }}.svc.kubernetes.{{ include "host_fqdn" . }}
{{- end }}

{{- define "_resolve_secret" -}}
    {{- $str := index . 0 -}}
    {{- $add_urlquery := index . 1 -}}
    {{- if (hasPrefix "vault+kvv2" $str) -}}
        {{"{{"}} resolve "{{ $str }}" {{ if $add_urlquery }}| urlquery {{ end }}{{"}}"}}
    {{- else -}}
        {{ $str }}
{{- end -}}
{{- end -}}

{{- define "resolve_secret" -}}
{{ include "_resolve_secret" (tuple . false) }}
{{- end -}}

{{- define "resolve_secret_urlquery" -}}
{{ include "_resolve_secret" (tuple . true) }}
{{- end -}}

{{- define "db_credentials" }}
    {{- $envAll := .context }}
    {{- $dbType := .dbType }}
    {{- if kindIs "map" $envAll }}
        {{- $dbConfig := dict }}
        {{- if eq $dbType "mariadb" }}
            {{- $dbConfig = $envAll.Values.mariadb }}
        {{- else if eq $dbType "pxc-db" }}
            {{- $dbConfig = $envAll.Values.pxc_db }}
        {{- end }}
        {{- if and $dbConfig.users $dbConfig.databases }}
            {{- $db := first $dbConfig.databases }}
            {{- $user := get $dbConfig.users $db | required (printf ".Values.db.%v.name & .password are required (key comes from first database in databases array)" $db) }}
            {{- $user.name | required (printf ".Values.db.%v.name is required!" $db ) }}:{{ $user.password | required (printf ".Values.db.%v.password is required!" $db ) }}
        {{- else }}
            {{- coalesce $envAll.Values.dbUser $envAll.Values.global.dbUser "root" }}:{{ coalesce $envAll.Values.dbPassword $envAll.Values.global.dbPassword $dbConfig.root_password | required ".Values.db.root_password is required!" }}
        {{- end }}
    {{- else }}
        {{- $user := index $envAll 2 }}
        {{- $password := index $envAll 3 }}
        {{- include "resolve_secret_urlquery" $user }}:{{ include "resolve_secret_urlquery" $password }}
    {{- end }}
{{- end }}

{{/*
Choose different db_url function depending on dbType value
Default: mariadb
*/}}
{{- define "utils.db_url" }}
{{- $dbUrlHelpers := dict
    "mariadb" "utils._db_url_mariadb"
    "pxc-db" "utils._db_url_pxc_db"
}}
{{- $dbType := default "mariadb" .Values.dbType }}
{{- $dbUrl := index $dbUrlHelpers $dbType }}
{{- include $dbUrl . }}
{{- end }}

{{/*
Choose different db_host function depending on dbType value
Default: mariadb
*/}}
{{- define "utils.db_host" }}
{{- $dbHostHelpers := dict
    "mariadb" "utils._db_host_mariadb"
    "pxc-db" "utils._db_host_pxc_db"
}}
{{- $dbType := default "mariadb" .Values.dbType }}
{{- $dbHost := index $dbHostHelpers $dbType }}
{{- include $dbHost . }}
{{- end }}

{{/*
Service hostname for mariadb
Example: service-mariadb
*/}}
{{- define "utils._db_host_mariadb" }}
    {{- if kindIs "map" . }}
        {{- .Values.mariadb.name }}
    {{- else }}
        {{- $envAll := index . 0 }}
        {{- if lt 4  (len .) }}
            {{- index . 4 }}
        {{- else }}
            {{- $envAll.Values.mariadb.name }}
        {{- end }}
    {{- end }}-mariadb
{{- end }}

{{/*
Service hostname for pxc-db
pxc-db provides following services:
- service-db-haproxy (*)
- service-db-haproxy-replicas
- service-db-pxc
- service-db-pxc-unready
Example: service-db-haproxy
*/}}
{{- define "utils._db_host_pxc_db" }}
    {{- if kindIs "map" . }}
        {{- .Values.pxc_db.name }}
    {{- else }}
        {{- $envAll := index . 0 }}
        {{- if lt 4  (len .) }}
            {{- index . 4 }}
        {{- else }}
            {{- $envAll.Values.pxc_db.name }}
        {{- end }}
    {{- end }}-db-haproxy
{{- end }}

{{/*
Backward-compatible function, which calls utils._db_url_mariadb
Returns example: service-mariadb
*/}}
{{- define "db_host_mysql" }}
{{- include "utils._db_host_mariadb" . }}
{{- end }}

{{/*
Backward-compatible function, which calls utils._db_url_mariadb
Returns example: mysql+pymysql://username:password@service-mariadb/dbname?charset=utf8
*/}}
{{- define "db_url_mysql" }}
{{- include "utils._db_url_mariadb" . }}
{{- end }}

{{/*
Function accepts tuple or map
1: Uses .Values.mariadb for connection URL generation
2: Uses provided tuple for connection URL generation
Tuple example: tuple . .Values.apidbName .Values.apidbUser .Values.apidbPassword .Values.mariadb_api.name
*/}}
{{- define "utils._db_url_mariadb" }}
    {{- if kindIs "map" . }}
        {{- if and .Values.mariadb.users .Values.mariadb.databases }}
            {{- $db := first .Values.mariadb.databases }}
            {{- $user := get .Values.mariadb.users $db | required (printf ".Values.mariadb.%v.name & .password are required (key comes from first database in .Values.mariadb.databases)" $db) }}
            {{- tuple . $db $user.name (required (printf "User with key %v requires password" $db) $user.password) | include "utils._db_url_mariadb" }}
        {{- else }}
            {{- tuple . (coalesce .Values.dbName .Values.db_name) (coalesce .Values.dbUser .Values.global.dbUser "root" | include "resolve_secret_urlquery") (coalesce .Values.dbPassword .Values.global.dbPassword .Values.mariadb.root_password | include "resolve_secret_urlquery" | required ".Values.mariadb.root_password is required!") .Values.mariadb.name | include "utils._db_url_mariadb" }}
        {{- end }}
    {{- else -}}
mysql+pymysql://{{ include "db_credentials" (dict "context" . "dbType" "mariadb") }}@
        {{- $allArgs := . }}
        {{- $schemaName := index . 1 }}
        {{- with $envAll := index . 0 }}
            {{- if not .Values.proxysql }}
                {{- include "utils._db_host_mariadb" $allArgs }}
            {{- else if not .Values.proxysql.mode }}
                {{- include "utils._db_host_mariadb" $allArgs }}
            {{- else if ne $envAll.Values.proxysql.mode "unix_socket" }}
                {{- if mustHas $envAll.Values.proxysql.mode (list "unix_socket" "host_alias") }}
                {{- include "utils._db_host_mariadb" $allArgs }}
                {{- else }}
                    {{ fail (printf "Unknown value for .Values.proxysql.mode: got \"%v\"" $envAll.Values.proxysql.mode) }}
                {{- end }}
            {{- end -}}
            /{{ $schemaName }}?
            {{- if .Values.proxysql }}
                {{- if eq .Values.proxysql.mode "unix_socket" -}}
                    unix_socket=/run/proxysql/mysql.sock&
                {{- end }}
            {{- end }}
        {{- end -}}
        charset=utf8
    {{- end }}
{{- end }}

{{/*
Function accepts tuple or map
1: Uses .Values.pxc_db for connection URL generation
2: Uses provided tuple for connection URL generation
Tuple example: tuple . .Values.apidbName .Values.apidbUser .Values.apidbPassword .Values.pxd_db_api.name
*/}}
{{- define "utils._db_url_pxc_db" }}
    {{- if kindIs "map" . }}
        {{- if and .Values.pxc_db.users .Values.pxc_db.databases }}
            {{- $db := first .Values.pxc_db.databases }}
            {{- $user := get .Values.pxc_db.users $db | required (printf ".Values.pxc_db.%v.name & .password are required (key comes from first database in .Values.pxc_db.databases)" $db) }}
            {{- tuple . $db $user.name (required (printf "User with key %v requires password" $db) $user.password) | include "utils._db_url_pxc_db" }}
        {{- else }}
            {{- tuple . (coalesce .Values.dbName .Values.db_name) (coalesce .Values.dbUser .Values.global.dbUser "root" | include "resolve_secret_urlquery") (coalesce .Values.dbPassword .Values.global.dbPassword .Values.pxc_db.root_password | include "resolve_secret_urlquery" | required ".Values.pxc_db.root_password is required!") .Values.pxc_db.name | include "utils._db_url_pxc_db" }}
        {{- end }}
    {{- else -}}
mysql+pymysql://{{ include "db_credentials" (dict "context" . "dbType" "pxc-db") }}@
        {{- $allArgs := . }}
        {{- $schemaName := index . 1 }}
        {{- with $envAll := index . 0 }}
            {{- if not .Values.proxysql }}
                {{- include "utils._db_host_pxc_db" $allArgs }}
            {{- else if not .Values.proxysql.mode }}
                {{- include "utils._db_host_pxc_db" $allArgs }}
            {{- else if ne $envAll.Values.proxysql.mode "unix_socket" }}
                {{- if mustHas $envAll.Values.proxysql.mode (list "unix_socket" "host_alias") }}
                {{- include "utils._db_host_pxc_db" $allArgs }}
                {{- else }}
                    {{ fail (printf "Unknown value for .Values.proxysql.mode: got \"%v\"" $envAll.Values.proxysql.mode) }}
                {{- end }}
            {{- end -}}
            /{{ $schemaName }}?
            {{- if .Values.proxysql }}
                {{- if eq .Values.proxysql.mode "unix_socket" -}}
                    unix_socket=/run/proxysql/mysql.sock&
                {{- end }}
            {{- end }}
        {{- end -}}
        charset=utf8
    {{- end }}
{{- end }}

{{/*
Alias for backward compatibility
*/}}
{{- define "db_url_pxc" }}
{{- include "utils._db_url_pxc_global" . }}
{{- end }}

{{/*
Custom DB URL for the global services using percona_cluster
*/}}
{{- define "utils._db_url_pxc_global" }}
{{- $prefix := "mysql+pymysql" }}
{{- $username := include "resolve_secret_urlquery" .Values.percona_cluster.db_user }}
{{- $password := include "resolve_secret_urlquery" .Values.percona_cluster.dbPassword }}
{{- $db_host := printf "%s-percona-pxc.%s.svc.kubernetes.%s.%s" .Release.Name .Release.Namespace .Values.global.db_region .Values.global.tld }}
{{- $db_name := .Values.percona_cluster.db_name }}
{{- $prefix }}://{{ $username }}:{{ $password }}@{{ $db_host }}/{{ $db_name }}?charset=utf8
{{- end }}

{{define "nova_db_host"}}nova-mariadb.{{ include "svc_fqdn" . }}{{end}}
{{define "nova_api_endpoint_host_admin"}}nova-api.{{ include "svc_fqdn" . }}{{end}}
{{define "nova_api_endpoint_host_internal"}}nova-api.{{ include "svc_fqdn" . }}{{end}}
{{define "nova_api_endpoint_host_public"}}compute-3.{{ include "host_fqdn" . }}{{end}}

{{define "nova_api_metadata_endpoint_host_internal"}}nova-api-metadata.{{ include "svc_fqdn" . }}{{end}}

{{define "placement_api_endpoint_host_admin"}}nova-placement-api.{{ include "svc_fqdn" . }}{{end}}
{{define "placement_api_endpoint_host_internal"}}nova-placement-api.{{ include "svc_fqdn" . }}{{end}}
{{define "placement_api_endpoint_host_public"}}placement-3.{{ include "host_fqdn" . }}{{end}}

{{define "internal_service"}}{{ $envAll := index . 0 }}{{ $service := index . 1 }}{{$service}}.{{$envAll.Release.Namespace}}.svc.kubernetes.{{$envAll.Values.global.region}}.{{$envAll.Values.global.tld}}{{ end }}

{{- define "svc.password_for_user_and_service" }}
    {{- $envAll := index . 0 }}
    {{- $user := index . 1 }}
    {{- $service := index . 2 }}
    {{- tuple $envAll ( $envAll.Values.global.user_suffix | default "" | print $user ) ( tuple $envAll $service | include "internal_service" ) ("long") }}
{{- end }}

{{define "nova_console_endpoint_host_public"}}compute-console-3.{{ include "host_fqdn" . }}{{end}}

{{define "horizon_endpoint_host"}}horizon-3.{{ include "host_fqdn" . }}{{end}}

{{define "keystone_api_endpoint_host_admin"}}keystone.{{ include "svc_fqdn" . }}{{end}}
{{define "keystone_api_endpoint_host_internal"}}keystone.{{ include "svc_fqdn" . }}{{end}}
{{define "keystone_api_endpoint_host_public"}}identity-3.{{ include "host_fqdn" . }}{{end}}

{{define "glance_db_host"}}glance-mariadb.{{ include "svc_fqdn" . }}{{end}}
{{define "glance_api_endpoint_host_admin"}}glance.{{ include "svc_fqdn" . }}{{end}}
{{define "glance_api_endpoint_host_internal"}}glance.{{ include "svc_fqdn" . }}{{end}}
{{define "glance_api_endpoint_host_public"}}image-3.{{ include "host_fqdn" . }}{{end}}

{{define "neutron_db_host"}}neutron-mariadb.{{ include "svc_fqdn" . }}{{end}}
{{define "neutron_api_endpoint_host_admin"}}neutron-server.{{ include "svc_fqdn" . }}{{end}}
{{define "neutron_api_endpoint_host_internal"}}neutron-server.{{ include "svc_fqdn" . }}{{end}}
{{define "neutron_api_endpoint_host_public"}}network-3.{{ include "host_fqdn" . }}{{end}}

{{define "ironic_db_host"}}ironic-mariadb.{{ include "svc_fqdn" . }}{{end}}
{{define "ironic_api_endpoint_host_admin"}}ironic-api.{{ include "svc_fqdn" . }}{{end}}
{{define "ironic_api_endpoint_host_internal"}}ironic-api.{{ include "svc_fqdn" . }}{{end}}
{{define "ironic_api_endpoint_host_public"}}baremetal-3.{{ include "host_fqdn" . }}{{end}}

{{define "ironic_console_endpoint_host_public"}}baremetal-console-3.{{ include "host_fqdn" . }}{{end}}

{{define "ironic_inspector_endpoint_host_admin"}}ironic-inspector.{{ include "svc_fqdn" . }}{{end}}
{{define "ironic_inspector_endpoint_host_internal"}}ironic-inspector.{{ include "svc_fqdn" . }}{{end}}
{{define "ironic_inspector_endpoint_host_public"}}baremetal-inspector-3.{{ include "host_fqdn" . }}{{end}}

{{define "barbican_db_host"}}barbican-mariadb.{{ include "svc_fqdn" . }}{{end}}
{{define "barbican_api_endpoint_host_admin"}}barbican-api.{{ include "svc_fqdn" . }}{{end}}
{{define "barbican_api_endpoint_host_internal"}}barbican-api.{{ include "svc_fqdn" . }}{{end}}
{{define "barbican_api_endpoint_host_public"}}keymanager-3.{{ include "host_fqdn" . }}{{end}}

{{define "cinder_db_host"}}cinder-mariadb.{{ include "svc_fqdn" . }}{{end}}
{{define "cinder_api_endpoint_host_admin"}}cinder-api.{{ include "svc_fqdn" . }}{{end}}
{{define "cinder_api_endpoint_host_internal"}}cinder-api.{{ include "svc_fqdn" . }}{{end}}
{{define "cinder_api_endpoint_host_public"}}volume-3.{{ include "host_fqdn" . }}{{end}}

{{define "manila_db_host"}}manila-mariadb.{{ include "svc_fqdn" . }}{{end}}
{{define "manila_api_endpoint_host_admin"}}manila-api.{{ include "svc_fqdn" . }}{{end}}
{{define "manila_api_endpoint_host_internal"}}manila-api.{{ include "svc_fqdn" . }}{{end}}
{{define "manila_api_endpoint_host_public"}}share-3.{{ include "host_fqdn" . }}{{end}}

{{define "designate_db_host"}}designate-mariadb.{{ include "svc_fqdn" . }}{{end}}
{{define "designate_api_endpoint_host_admin"}}designate-api.{{ include "svc_fqdn" . }}{{end}}
{{define "designate_api_endpoint_host_internal"}}designate-api.{{ include "svc_fqdn" . }}{{end}}
{{define "designate_api_endpoint_host_public"}}dns-3.{{ include "host_fqdn" . }}{{end}}

{{define "octavia_db_host"}}octavia-mariadb.{{ include "svc_fqdn" . }}{{end}}
{{define "octavia_api_endpoint_host_admin"}}octavia-api.{{ include "svc_fqdn" . }}{{end}}
{{define "octavia_api_endpoint_host_internal"}}octavia-api.{{ include "svc_fqdn" . }}{{end}}
{{define "octavia_api_endpoint_host_public"}}loadbalancer-3.{{ include "host_fqdn" . }}{{end}}

{{define "andromeda_api_endpoint_public"}}gtm-3.{{ include "host_fqdn" . }}{{end}}
{{define "arc_api_endpoint_host_public"}}arc.{{ include "host_fqdn" . }}{{end}}
{{define "archer_api_endpoint_public"}}archer.{{ include "host_fqdn" . }}{{end}}
{{define "lyra_api_endpoint_host_public"}}lyra.{{ include "host_fqdn" . }}{{end}}
{{define "webcli_api_endpoint_host_public"}}webcli.{{ include "host_fqdn" . }}{{end}}

{{define "swift_endpoint_host"}}objectstore-3.{{ include "host_fqdn" . }}{{end}}

{{define "cfm_api_endpoint_host_public"}}cfm.{{ include "host_fqdn" . }}{{end}}

{{define "sftp_api_endpoint_host"}}sftp-bridge.{{ .Values.global.region }}.{{ .Values.global.tld }}{{end}}

{{ define "f5_url" }}
    {{- $host := index . 0 }}
    {{- $user := index . 1 }}
    {{- $password := index . 2 -}}
https://{{ include "resolve_secret_urlquery" $user }}:{{ include "resolve_secret_urlquery" $password }}@{{ $host }}
{{- end }}

{{- define "utils.bigip_url" }}
    {{- $envAll := index . 0 }}
    {{- $host := index . 1 }}
    {{- tuple $host ( $envAll.Values.global.bigip_user | required ".Values.global.bigip_user required!") ( $envAll.Values.global.bigip_password | required ".Values.global.bigip_password required!") | include "f5_url" }}
{{- end }}

{{- define "utils.bigip_urls" }}
    {{- $envAll := index . 0 }}
    {{- $hosts := index . 1 }}
    {{- range $i, $value := $hosts }}
        {{- if ne $i 0 }}, {{ end -}}
        {{- tuple $envAll $value | include "utils.bigip_url" -}}
    {{- end }}
{{- end }}
