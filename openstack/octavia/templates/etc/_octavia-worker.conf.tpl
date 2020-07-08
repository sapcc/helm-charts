{{- define "octavia_worker_conf" -}}
{{- $values := index . 0 -}}
{{- $lb_name := index . 1 -}}
{{- $loadbalancer := index . 2 -}}
[DEFAULT]
host = {{ $lb_name }}

[f5_agent]
bigip_urls = {{ $loadbalancer.bigip_urls | join ", " }}
bigip_verify = false
bigip_token = true
esd_dir = /etc/octavia/esd
sync_to_group = {{ default "" $loadbalancer.sync_to_group }}

# Use FastL4 for TCP listener if possible
tcp_service_type = Service_L4

# Use the virtual-server address as SNAT address
snat_virtual = true

# Use selective icmp echo for virtual addresses
# DISABLED: due to deletion errors
# service_address_icmp_echo = selective

# Default profiles
{{- range $key, $value := $values.default_profiles }}
{{ $key }} = {{ $value }}
{{- end }}

# Migration Mode ?
migration = {{ $loadbalancer.migration | default "false" }}

# Default Server TLS Cipher
[f5_tls_server]
default_ciphers = {{ $values.default_ciphers }}
tls_1_0 = {{ $values.default_tls_1_0 }}
tls_1_1 = {{ $values.default_tls_1_1 }}

{{- if $values.external_as3 }}
# External AS3 Endpoint
as3_endpoint = octavia-f5-as3.{{ include "svc_fqdn" . }}
{{- end }}

{{- end }}