[global]


[default]
graphite_enabled  = 1
graphite_server   = localhost
graphite_port     = 2003
graphite_proto    = tcp

host_type         = FILER
auth_type         = password
username          = ntap-hvest
password          = prometheusrocks10
data_update_freq  = 60

[filer-0]
hostname    = 10.44.58.21
group       = filers