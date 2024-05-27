{{- range $host, $ucs := .Values.cisco_ucsm_bm }}
{{- if ne $host "example.com"}}
[ml2_cisco_ucsm_bm_ip:{{$host}}]
ucsm_username = {{required "A valid ucs-config required!" $ucs.user}}
ucsm_password = {{required "A valid ucs-config required!" $ucs.password}}
{{- end }}
{{- end }}
