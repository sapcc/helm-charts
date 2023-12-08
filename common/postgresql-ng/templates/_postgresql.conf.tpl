# extension loading
shared_preload_libraries = '{{ keys .Values.extensions | sortAlpha | join ","}}'
{{- range $k, $v := .Values.extensions }}
{{- range $k2, $v2 := $v }}
{{$k}}.{{$k2}} = {{$v2}}
{{- end }}
{{- end }}

# set default settings from a freshly generated postgresql.conf
listen_addresses = '*'
shared_buffers = 128MB
dynamic_shared_memory_type = posix
max_wal_size = 1GB
min_wal_size = 80MB
log_timezone = 'Etc/UTC'
datestyle = 'iso, mdy'
timezone = 'Etc/UTC'
lc_messages = 'en_US.utf8'
lc_monetary = 'en_US.utf8'
lc_numeric = 'en_US.utf8'
lc_time = 'en_US.utf8'
default_text_search_config = 'pg_catalog.english'

# none default settings that cannot be changed with helm values
password_encryption = 'scram-sha-256'

# settings which can be changed by helm values
# those are kept small on purpose to keep complexity small
log_min_duration_statement = {{ .Values.config.log_min_duration_statement }}
max_connections = {{.Values.config.max_connections }}
random_page_cost = {{.Values.config.random_page_cost }}
