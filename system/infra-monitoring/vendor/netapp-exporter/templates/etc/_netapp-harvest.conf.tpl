[global]

[default]
graphite_enabled  = 1
graphite_server   = localhost
graphite_port     = 2003
graphite_proto    = tcp

host_type         = FILER
auth_type         = password
data_update_freq  = 60

{{- range $idx, $share := .Values.global.netapp.filers }}

[{{ $share.name }}]
hostname = {{ $share.host }}
username = {{ required "netapp.filers.*.username" $share.username }}
password = {{ required "netapp.filers.*.password" $share.password }}

{{- with $share.host | regexFind "bb|cp|bm|md" }}
{{- if eq . "bb" }}
group    = vpod
{{- else if eq . "cp" }}
group    = control-plane
{{- else if eq . "bm" }}
group    = bare-metal
{{- else if eq . "md" }}
group    = manila
{{- else }}
group    = others
{{- end }}

{{- end }}
{{- end }}