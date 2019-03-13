[global]

[default]
graphite_enabled  = 1
graphite_server   = localhost
graphite_port     = 2003
graphite_proto    = tcp

host_type         = FILER
auth_type         = password
data_update_freq  = 300

{{- range $idx, $share := .Values.netapp.filers }}

[{{ $share.name }}]
hostname = {{ $share.host }}
username = {{ required "netapp.filers.*.username" $share.username }}
password = {{ required "netapp.filers.*.password" $share.password }}

{{- with $share.name | regexFind "bb|cp|bm|ma" }}
{{- if eq . "bb" }}
group    = vpod
{{- else if eq . "cp" }}
group    = control-plane
{{- else if eq . "bm" }}
group    = bare-metal
{{- else if eq . "ma" }}
group    = manila
{{- else }}
group    = others
{{- end }}

{{- end }}
{{- end }}