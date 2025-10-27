listen on *

{{- range $i, $s := .Values.ntp_server}}
server {{ $s.server }}
{{- end}}
server 127.127.1.0
fudge 127.127.1.0 stratum 10
