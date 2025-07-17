{{- define "identity_service_url" -}}
https://identity-3.{{.Values.global.region}}.{{.Values.global.tld}}/v3
{{- end }}

{{- define "console-novnc.conf" }}
{{- $cell_name := index . 1 }}
{{- $config := index . 2 }}
{{- with index . 0 }}
[vnc]
enabled = {{ $config.enabled }}
{{- if $config.enabled }}
novncproxy_base_url = https://{{include "nova_console_endpoint_host_public" .}}:{{ .Values.global.novaConsolePortPublic }}/{{ $cell_name }}/novnc/vnc_auto.html?path=/{{ $cell_name }}/novnc/websockify
{{- end }}
{{- end }}
{{- end }}
