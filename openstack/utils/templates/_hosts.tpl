{{- define "svc_fqdn" -}}
{{ .Release.Namespace }}.svc.kubernetes.{{ .Values.global.region }}.{{ .Values.global.tld }}
{{- end }}

{{define "db_url" }}
    {{- if kindIs "map" . -}}
postgresql+psycopg2://{{default .Values.dbUser .Values.global.dbUser}}:{{(default .Values.dbPassword .Values.global.dbPassword) | default (tuple . (default .Values.dbUser .Values.global.dbUser) | include "postgres.password_for_user")}}@{{.Chart.Name}}-postgresql.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}:5432/{{.Values.postgresql.postgresDatabase}}
    {{- else }}
        {{- $envAll := index . 0 }}
        {{- $name := index . 1 }}
        {{- $user := index . 2 }}
        {{- $password := index . 3 }}
        {{- with $envAll -}}
postgresql+psycopg2://{{$user}}:{{$password | urlquery}}@{{.Chart.Name}}-postgresql.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}:5432/{{$name}}
        {{- end }}
    {{- end -}}
?connect_timeout=10&keepalives_idle=5&keepalives_interval=5&keepalives_count=10
{{- end}}

{{define "db_host_mysql"}}{{.Release.Name}}-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "db_url_mysql" }}
    {{- if kindIs "map" . -}}
mysql+pymysql://root:{{.Values.mariadb.root_password | required ".Values.mariadb.root_password is required!" }}@{{include "db_host_mysql" .}}/{{.Values.db_name}}
    {{- else }}
        {{- $envAll := index . 0 }}
        {{- $name := index . 1 }}
        {{- $user := index . 2 }}
        {{- $password := index . 3 }}
        {{- with $envAll -}}
mysql+pymysql://{{$user}}:{{$password | urlquery}}@{{include "db_host_mysql" .}}/{{$name}}
        {{- end }}
    {{- end -}}
?charset=utf8
{{- end}}

{{define "db_host_pxc"}}{{.Release.Name}}-percona-pxc.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.db_region}}.{{.Values.global.tld}}{{end}}

{{define "db_url_pxc" }}mysql+pymysql://{{.Values.percona_cluster.db_user }}:{{.Values.percona_cluster.dbPassword }}@{{include "db_host_pxc" .}}/{{.Values.percona_cluster.db_name}}?charset=utf8{{end}}

{{define "nova_db_host"}}nova-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "nova_api_endpoint_host_admin"}}nova-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "nova_api_endpoint_host_internal"}}nova-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "nova_api_endpoint_host_public"}}compute-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "nova_api_metadata_endpoint_host_internal"}}nova-api-metadata.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "placement_api_endpoint_host_admin"}}nova-placement-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "placement_api_endpoint_host_internal"}}nova-placement-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "placement_api_endpoint_host_public"}}placement-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "internal_service"}}{{ $envAll := index . 0 }}{{ $service := index . 1 }}{{$service}}.{{$envAll.Release.Namespace}}.svc.kubernetes.{{$envAll.Values.global.region}}.{{$envAll.Values.global.tld}}{{ end }}

{{- define "svc.password_for_user_and_service" }}
    {{- $envAll := index . 0 }}
    {{- $user := index . 1 }}
    {{- $service := index . 2 }}
    {{- tuple $envAll ( $envAll.Values.global.user_suffix | default "" | print $user ) ( tuple $envAll $service | include "internal_service" ) ("long") }}
{{- end }}

{{define "nova_console_endpoint_host_public"}}compute-console-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "horizon_endpoint_host"}}horizon-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "keystone_api_endpoint_host_admin"}}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "keystone_api_endpoint_host_internal"}}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "keystone_api_endpoint_host_public"}}identity-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "glance_db_host"}}glance-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "glance_api_endpoint_host_admin"}}glance.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "glance_api_endpoint_host_internal"}}glance.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "glance_api_endpoint_host_public"}}image-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "neutron_db_host"}}neutron-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "neutron_api_endpoint_host_admin"}}neutron-server.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "neutron_api_endpoint_host_internal"}}neutron-server.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "neutron_api_endpoint_host_public"}}network-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "ironic_db_host"}}ironic-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "ironic_api_endpoint_host_admin"}}ironic-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "ironic_api_endpoint_host_internal"}}ironic-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "ironic_api_endpoint_host_public"}}baremetal-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "ironic_console_endpoint_host_public"}}baremetal-console-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "ironic_inspector_endpoint_host_admin"}}ironic-inspector.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "ironic_inspector_endpoint_host_internal"}}ironic-inspector.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "ironic_inspector_endpoint_host_public"}}baremetal-inspector-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "barbican_db_host"}}barbican-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "barbican_api_endpoint_host_admin"}}barbican-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "barbican_api_endpoint_host_internal"}}barbican-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "barbican_api_endpoint_host_public"}}keymanager-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "cinder_db_host"}}cinder-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "cinder_api_endpoint_host_admin"}}cinder-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "cinder_api_endpoint_host_internal"}}cinder-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "cinder_api_endpoint_host_public"}}volume-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "manila_db_host"}}manila-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "manila_api_endpoint_host_admin"}}manila-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "manila_api_endpoint_host_internal"}}manila-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "manila_api_endpoint_host_public"}}share-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "designate_db_host"}}designate-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "designate_api_endpoint_host_admin"}}designate-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "designate_api_endpoint_host_internal"}}designate-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "designate_api_endpoint_host_public"}}dns-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "octavia_db_host"}}octavia-mariadb.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "octavia_api_endpoint_host_admin"}}octavia-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "octavia_api_endpoint_host_internal"}}octavia-api.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "octavia_api_endpoint_host_public"}}loadbalancer-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "arc_api_endpoint_host_public"}}arc.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "lyra_api_endpoint_host_public"}}lyra.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}
{{define "webcli_api_endpoint_host_public"}}webcli.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "swift_endpoint_host"}}objectstore-3.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

{{define "cfm_api_endpoint_host_public"}}cfm.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}

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
https://{{ $user }}:{{ $password | urlquery }}@{{ $host }}
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
