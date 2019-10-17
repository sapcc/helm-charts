[global]

[default]
graphite_enabled  = 1
graphite_server   = localhost
graphite_port     = {{ .Values.exporter.graphitePort }}
graphite_proto    = tcp

host_type         = FILER
auth_type         = password
data_update_freq  = 60
