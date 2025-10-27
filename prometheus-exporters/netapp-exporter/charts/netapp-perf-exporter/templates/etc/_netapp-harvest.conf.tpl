[global]

[default]
graphite_enabled  = 1
graphite_server   = localhost
{{- if .dupEnabled }}
graphite_port     = {{ .Values.ports.dupInPort }}
{{- else }}
graphite_port     = {{ .Values.ports.graphiteExporterInPort }}
{{- end }}
graphite_proto    = tcp

host_type         = FILER
auth_type         = password
data_update_freq  = {{ .Values.harvest.update_interval | default 60 }}

latency_io_reqd   = 0
