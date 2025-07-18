{{- define "octavia_worker_conf" -}}
{{- $envAll := index . 0 -}}
{{- $lb_name := index . 1 -}}
{{- $loadbalancer := index . 2 -}}
[DEFAULT]
host = {{ $lb_name }}
backdoor_socket = /var/lib/octavia/backdoor.socket

[networking]
{{- if $loadbalancer.physical_interface_mapping }}
physical_interface_mapping = {{ $loadbalancer.physical_interface_mapping }}
{{- end }}
{{- if eq $loadbalancer.model "r5900" }}
vcmp_rseries = true
{{- end }}

[f5_agent]
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

# Unchecked Mode (Skip F5 running configuration check when applying AS3 declarations)
unchecked_mode = {{ $envAll.Values.unchecked_mode | default "false" }}

{{- end }}
