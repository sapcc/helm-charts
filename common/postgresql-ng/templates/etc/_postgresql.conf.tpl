# extension loading
shared_preload_libraries = '{{ keys .Values.extensions | sortAlpha | join ","}}'		# (change requires restart)
{{- range $k, $v := .Values.extensions }}
{{- range $k2, $v2 := $v }}
{{$k}}.{{$k2}} = {{$v2}}
{{- end }}
{{- end }}

# set default settings from a freshly generated postgresql.conf
listen_addresses = '*'    # what IP address(es) to listen on;
shared_buffers = 128MB      # min 128kB
dynamic_shared_memory_type = posix  # the default is usually the first option
max_wal_size = 1GB
min_wal_size = 80MB
log_timezone = 'Etc/UTC'
datestyle = 'iso, mdy'
timezone = 'Etc/UTC'
lc_messages = 'en_US.utf8'      # locale for system error message
lc_monetary = 'en_US.utf8'      # locale for monetary formatting
lc_numeric = 'en_US.utf8'     # locale for number formatting
lc_time = 'en_US.utf8'        # locale for time formatting
default_text_search_config = 'pg_catalog.english'

# settings which can be changed by helm values
# those are kept small on purpose to keep complexity small
log_min_duration_statement = {{ .Values.config.log_min_duration_statement }}
max_connections = {{.Values.config.max_connections }}
random_page_cost = {{.Values.config.random_page_cost }}
