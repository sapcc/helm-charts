{{- if or (eq .Values.global.region "qa-de-1") (eq .Values.global.region "qa-de-2") }}
log-queries
log-facility=/var/log/dnsmasq.log
{{- end }}
{{- if .Values.agent.dhcp.ntp_server }}
dhcp-option=option:ntp-server,{{ .Values.agent.dhcp.ntp_server | join "," }}
{{- end }}
no-negcache
{{- range .Values.dnsmasq.dhcp_options }}
dhcp-option={{ . }}
{{- end }}
local=/{{required "A valid .Values.dns_local_domain is required!" .Values.dns_local_domain }}/
