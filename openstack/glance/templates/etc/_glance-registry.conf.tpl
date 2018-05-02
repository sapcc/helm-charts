[DEFAULT]
debug = {{.Values.registry.debug}}

log_config_append = /etc/glance/logging.conf

#disable default admin rights for role 'admin'
admin_role = ''

rpc_response_timeout = {{ .Values.rpc_response_timeout | default 300 }}
rpc_workers = {{ .Values.rpc_workers | default 1 }}

wsgi_default_pool_size = {{ .Values.wsgi_default_pool_size | default 100 }}
max_pool_size = {{ .Values.max_pool_size | default 5 }}
max_overflow = {{ .Values.max_overflow | default 10 }}

[database]
connection = postgresql://{{ .Values.postgresql.dbUser }}:{{ .Values.postgresql.dbPassword }}@{{include "db_host" .}}:5432/{{.Values.postgresql.postgresDatabase}}

[keystone_authtoken]
{{- if .Values.keystone.authUri }}
auth_uri = {{.Values.keystone.authUri }}
{{- else }}
auth_uri = {{include "keystone_url" .}}
{{- end }}
{{- if .Values.keystone.authUrl }}
auth_url = {{.Values.keystone.authUrl }}
{{- else }}
auth_url = {{include "keystone_url" .}}/v3
{{- end }}
auth_type = v3password
username = {{ .Values.keystone.username | default "glance" | quote}}
password = {{ .Values.keystone.password }}
{{- if .Values.keystone.userDomainName }}
user_domain_name = {{ .Values.keystone.userDomainName }}
{{- end }}
{{- if .Values.keystone.userDomainId }}
user_domain_id = {{ .Values.keystone.userDomainId }}
{{- end }}
{{- if .Values.keystone.projectName }}
project_name = {{ .Values.keystone.projectName }}
{{- end }}
{{- if .Values.keystone.projectDomainName }}
project_domain_name = {{ .Values.keystone.projectDomainName }}
{{- end }}
{{- if .Values.keystone.projectDomainId }}
project_domain_id = {{ .Values.keystone.projectDomainId }}
{{- end }}
insecure = True

[paste_deploy]
flavor = keystone

[oslo_messaging_notifications]
driver = noop
