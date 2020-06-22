{{- define "f5_agent_conf_ini" -}}
{{- $context := index . 0 -}}
{{- $loadbalancer := index . 1 -}}
[DEFAULT]
host = {{ $loadbalancer.name }}

[F5]
physical_device_mappings = {{ $loadbalancer.physical_device_mappings }}
sync_interval = {{ $context.Values.new_f5.periodic_interval }}
backend = icontrol
devices = {{ range $i, $host := $loadbalancer.hosts }}
cleanup = {{ $loadbalancer.cleanup | default "false" }}
migration = {{ $context.Values.migration | default "false" }}
{{- tuple $host $loadbalancer.username $loadbalancer.password | include "f5_url" }}
{{- if lt $i (sub (len $loadbalancer.hosts) 1) }},{{ end -}}
{{- end }}

[F5_VCMP]
username = {{ required "Missing loadbalancer username!" $loadbalancer.username }}
password = {{ required "Missing loadbalancer password!" $loadbalancer.password }}
hosts_guest_mappings = {{ $loadbalancer.vcmp_host_guest_mapping | join "," }}
{{- end -}}