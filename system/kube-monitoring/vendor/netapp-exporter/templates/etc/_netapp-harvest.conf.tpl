[global]


[default]
graphite_enabled  = 1
graphite_server   = localhost
graphite_port     = 2003
graphite_proto    = tcp

host_type         = FILER
auth_type         = password
username          = {{ .Values.global.netapp_filer.username | default "dummyuser" }}
password          = {{ .Values.global.netapp_filer.password | default "******" }}
data_update_freq  = 60

{{ .Values.netapp.filers | indent 0 }}
