{{- if .Values.new_f5.migration }}
[DEFAULT]
debug = True

[migration]
# Run making changes
trial_run=False

# Don't delete the load balancer records from neutron-lbaas after migration
delete_after_migration=False

# Connection string for the neutron database
neutron_db_connection = {{ include "db_url_mysql" . }}

# Connection string for the octavia database
octavia_db_connection = mysql+pymysql://root:{{ .Values.new_f5.octavia_db_password | required "new_f5.octavia_db_password required"}}@{{ include "octavia_db_host" . }}/octavia
{{- end }}