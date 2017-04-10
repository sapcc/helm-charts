[DEFAULT]
# Show debugging output in logs (sets DEBUG log level output)
debug = {{ .Values.api.debug }}

# Address to bind the API server
bind_host = 0.0.0.0

# Port to bind the API server to
bind_port =  9311

# Host name, for use in HATEOAS-style references
#  Note: Typically this would be the load balanced endpoint that clients would use
#  communicate back with this service.
# If a deployment wants to derive host from wsgi request instead then make this
# blank. Blank is needed to override default config value which is
# 'http://localhost:9311'.
host_href = {{.Values.services.api.scheme}}://{{ .Values.services.api.host }}:{{ default "9311" .Values.services.api.port }}

# Log to this file. Make sure you do not set the same log
# file for both the API and registry servers!
#log_file = /var/log/barbican/api.log

# Backlog requests when creating socket
backlog = 4096

# TCP_KEEPIDLE value in seconds when creating socket.
# Not supported on OS X.
#tcp_keepidle = 600

# Maximum allowed http request size against the barbican-api
max_allowed_secret_in_bytes = 10000
max_allowed_request_size_in_bytes = 1000000

# SQLAlchemy connection string for the reference implementation
# registry server. Any valid SQLAlchemy connection string is fine.
# See: http://www.sqlalchemy.org/docs/05/reference/sqlalchemy/connections.html#sqlalchemy.create_engine
# Uncomment this for local dev, putting db in project directory:
#sql_connection = sqlite:///barbican.sqlite
# Note: For absolute addresses, use '////' slashes after 'sqlite:'
# Uncomment for a more global development environment

sql_connection = postgresql://{{ .Values.postgresql.dbUser }}:{{ .Values.postgresql.dbPassword }}@{{include "db_host" .}}:5432/{{.Values.postgresql.postgresDatabase}}

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
{{- if .Values.memcached }}
memcache_servers = {{include "memcached_host" .}}:{{.Values.memcached.port}}
{{- end}}
insecure = True
