{{- define "host_fqdn" -}}
{{ .Values.global.region }}.{{ .Values.global.tld }}
{{- end }}

{{- define "svc_fqdn" -}}
{{ .Release.Namespace }}.svc.kubernetes.{{ include "host_fqdn" . }}
{{- end }}

{{define "db_url" }}
    {{- if kindIs "map" . -}}
postgresql+psycopg2://{{default .Values.dbUser .Values.global.dbUser}}:{{(default .Values.dbPassword .Values.global.dbPassword) | default (tuple . (default .Values.dbUser .Values.global.dbUser) | include "postgres.password_for_user")}}@{{.Chart.Name}}-postgresql.{{ include "svc_fqdn" . }}:5432/{{.Values.postgresql.postgresDatabase}}
    {{- else }}
        {{- $envAll := index . 0 }}
        {{- $name := index . 1 }}
        {{- $user := index . 2 }}
        {{- $password := index . 3 }}
        {{- with $envAll -}}
postgresql+psycopg2://{{$user}}:{{$password | urlquery}}@{{.Chart.Name}}-postgresql.{{ include "svc_fqdn" . }}:5432/{{$name}}
        {{- end }}
    {{- end -}}
?connect_timeout=10&keepalives_idle=5&keepalives_interval=5&keepalives_count=10
{{- end}}

{{- define "db_credentials" }}
    {{- if kindIs "map" . }}
        {{- if and .Values.mariadb.users .Values.mariadb.databases }}
            {{- $db := first .Values.mariadb.databases }}
            {{- $user := get .Values.mariadb.users $db | required (printf ".Values.mariadb.%v.name & .password are required (key comes from first database in .Values.mariadb.databases)" $db) }}
            {{- $user.name | required (printf ".Values.mariadb.%v.name is required!" $db ) }}:{{ $user.password | required (printf ".Values.mariadb.%v.password is required!" $db ) }}
        {{- else }}
            {{- coalesce .Values.dbUser .Values.global.dbUser "root" }}:{{ coalesce .Values.dbPassword .Values.global.dbPassword .Values.mariadb.root_password | required ".Values.mariadb.root_password is required!" }}
        {{- end }}
    {{- else }}
        {{- $user := index . 2 }}
        {{- $password := index . 3 }}
        {{- $user }}:{{ $password }}
    {{- end }}
{{- end }}

{{- define "db_host_mysql" }}
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

{{- define "db_url_mysql" }}
    {{- if kindIs "map" . }}
        {{- if and .Values.mariadb.users .Values.mariadb.databases }}
            {{- $db := first .Values.mariadb.databases }}
            {{- $user := get .Values.mariadb.users $db | required (printf ".Values.mariadb.%v.name & .password are required (key comes from first database in .Values.mariadb.databases)" $db) }}
            {{- tuple . $db $user.name (required (printf "User with key %v requires password" $db) $user.password) | include "db_url_mysql" }}
        {{- else }}
            {{- tuple . (coalesce .Values.dbName .Values.db_name) (coalesce .Values.dbUser .Values.global.dbUser "root") (coalesce .Values.dbPassword .Values.global.dbPassword .Values.mariadb.root_password | required ".Values.mariadb.root_password is required!") .Values.mariadb.name | include "db_url_mysql" }}
        {{- end }}
    {{- else -}}
mysql+pymysql://{{ include "db_credentials" . }}@
        {{- $allArgs := . }}
        {{- $schemaName := index . 1 }}
        {{- with $envAll := index . 0 }}
            {{- if not .Values.proxysql }}
                {{- include "db_host_mysql" $allArgs }}
            {{- else if not .Values.proxysql.mode }}
                {{- include "db_host_mysql" $allArgs }}
            {{- else if ne $envAll.Values.proxysql.mode "unix_socket" }}
                {{- if mustHas $envAll.Values.proxysql.mode (list "unix_socket" "host_alias") }}
                {{- include "db_host_mysql" $allArgs }}
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
{{- end}}

# Please keep as it is, special case when it has to reference the db_region value.
{{define "db_host_pxc"}}{{.Release.Name}}-percona-pxc.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.db_region}}.{{.Values.global.tld}}{{end}}

{{define "db_url_pxc" }}mysql+pymysql://{{.Values.percona_cluster.db_user }}:{{.Values.percona_cluster.dbPassword }}@{{include "db_host_pxc" .}}/{{.Values.percona_cluster.db_name}}?charset=utf8{{end}}

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

{{- define "identity.password_for_user" }}
    {{- $envAll := index . 0 }}
    {{- $user := index . 1 }}
    {{- tuple $envAll ( $envAll.Values.global.user_suffix | default "" | print $user ) ( include "keystone_api_endpoint_host_public" $envAll ) ("long")| fail "You need to pass an individual password." }}
{{- end }}

{{ define "f5_url" }}
    {{- $host := index . 0 }}
    {{- $user := index . 1 }}
    {{- $password := index . 2 -}}
https://{{ $user }}:{{ $password }}@{{ $host }}
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
