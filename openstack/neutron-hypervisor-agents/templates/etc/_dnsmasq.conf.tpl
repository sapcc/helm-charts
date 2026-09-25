{{- range $k, $v := .Values.dnsmasq.conf }}
    {{- if typeIsLike "bool" $v }}
        {{- if $v }}
{{ $k }}
        {{- end }}
    {{- else }}
{{ $k }}={{ $v }}
    {{- end }}
{{- end }}
{{- range .Values.dnsmasq.dhcp_options }}
dhcp-option={{ . }}
{{- end }}
local=/{{required "A valid .Values.dns_local_domain is required!" .Values.dns_local_domain }}/
