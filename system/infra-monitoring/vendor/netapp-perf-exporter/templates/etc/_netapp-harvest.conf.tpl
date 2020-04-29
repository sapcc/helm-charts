[global]

[default]
graphite_enabled  = 1
graphite_server   = localhost
{{- if .dupEnabled }}
graphite_port     = {{ .Values.ports.harvestOutPort }}
{{- else }}
graphite_port     = {{ .Values.ports.graphiteInPort }}
{{- end }}
graphite_proto    = tcp

host_type         = FILER
auth_type         = password
data_update_freq  = 60
