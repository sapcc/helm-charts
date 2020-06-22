{{- define "f5_agent_conf_ini" -}}
{{- $values := index . 0 -}}
{{- $loadbalancer := index . 1 -}}
[DEFAULT]
host = {{ $loadbalancer.name }}

[F5]
physical_device_mappings = {{ $loadbalancer.physical_device_mappings }}
sync_interval = {{ $values.new_f5.periodic_interval }}
cleanup = {{ $loadbalancer.cleanup | default "false" }}
migration = {{ $values.migration | default "false" }}
backend = icontrol
devices = {{ range $i, $host := $loadbalancer.hosts }}
{{- tuple $host $loadbalancer.username $loadbalancer.password | include "f5_url" }}
{{- if lt $i (sub (len $loadbalancer.hosts) 1) }}, {{ end -}}
{{- end }}

[F5_VCMP]
username = {{ required "Missing loadbalancer username!" $loadbalancer.username }}
password = {{ required "Missing loadbalancer password!" $loadbalancer.password }}
hosts_guest_mappings = {{ $loadbalancer.vcmp_host_guest_mapping | join "," }}
{{- end -}}