{{- if or (eq .Values.global.region "qa-de-1") (eq .Values.global.region "staging") }}
log-queries
log-facility=/var/log/dnsmasq.log
{{- end }}
{{- if .Values.agent.dhcp.ntp_server }}
dhcp-option=option:ntp-server,{{ .Values.agent.dhcp.ntp_server | join "," }}
{{- end }}
