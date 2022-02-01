{{- define "octavia_worker_conf" -}}
{{- $envAll := index . 0 -}}
{{- $lb_name := index . 1 -}}
{{- $loadbalancer := index . 2 -}}
[DEFAULT]
host = {{ $lb_name }}

[networking]
{{- if $loadbalancer.physical_interface_mapping }}
physical_interface_mapping = {{ $loadbalancer.physical_interface_mapping }}
{{- end }}
{{- if $loadbalancer.vcmps }}
vcmp_urls = {{ tuple $envAll $loadbalancer.vcmps | include "utils.bigip_urls" -}}
{{- end }}
{{- if $loadbalancer.override_vcmp_guest_names }}
override_vcmp_guest_names = {{ $loadbalancer.override_vcmp_guest_names | join ", " -}}
{{- end }}


[f5_agent]
bigip_urls = {{ if $loadbalancer.devices -}}{{- tuple $envAll $loadbalancer.devices | include "utils.bigip_urls" -}}{{- else -}}{{ $loadbalancer.bigip_urls | join ", " }}{{- end }}
bigip_verify = false
bigip_token = true
esd_dir = /etc/octavia/esd
sync_to_group = {{ default "" $loadbalancer.sync_to_group }}
persist_every = {{ $envAll.Values.persist_every }}
availability_zone = {{ default "" $loadbalancer.availability_zone }}

# Use FastL4 for TCP listener if possible
tcp_service_type = Service_L4

# Use the virtual-server address as SNAT address
snat_virtual = true

# Use selective icmp echo for virtual addresses
# DISABLED: due to deletion errors
# service_address_icmp_echo = selective

# Default profiles
{{- range $key, $value := $envAll.Values.default_profiles }}
{{ $key }} = {{ $value }}
{{- end }}

# Migration Mode ?
migration = {{ $loadbalancer.migration | default "false" }}

{{- if $envAll.Values.external_as3 }}
# External AS3 Endpoint
as3_endpoint = https://octavia-f5-as3.{{ include "svc_fqdn" $envAll }}
{{- end }}

# Async Mode (always use async tasks)
async_mode = {{ $envAll.Values.async_mode | default "false" }}

# Unsafe Mode (don't check F5 running configuration when applying declarations)
unsafe_mode = {{ $envAll.Values.unsafe_mode | default "false" }}

# Default Server TLS Cipher
[f5_tls_server]
default_ciphers = {{ $envAll.Values.default_ciphers }}
tls_1_0 = {{ $envAll.Values.default_tls_1_0 }}
tls_1_1 = {{ $envAll.Values.default_tls_1_1 }}

{{- end }}
