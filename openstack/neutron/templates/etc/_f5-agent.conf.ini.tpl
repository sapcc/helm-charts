{{- define "f5_agent_conf_ini" -}}
{{- $envAll := index . 0 -}}
{{- $loadbalancer := index . 1 -}}
[DEFAULT]
host = {{ $loadbalancer.name }}

[F5]
physical_device_mappings = {{ $loadbalancer.physical_device_mappings }}
sync_interval = {{ $envAll.Values.new_f5.periodic_interval }}
cleanup = {{ $envAll.Values.new_f5.cleanup | default "false" }}
migration = {{ $envAll.Values.new_f5.migration | default "false" }}
backend = icontrol
devices = {{ range $i, $host := $loadbalancer.hosts }}
{{- tuple $envAll $host | include "utils.bigip_url"}}
{{- if lt $i (sub (len $loadbalancer.hosts) 1) }}, {{ end -}}
{{- end }}

[F5_VCMP]
hosts_guest_mappings = {{ $local := dict "first" true -}}
{{- range $host, $guest_name := $loadbalancer.vcmp_host_guest_mapping }}
    {{- if not $local.first }}, {{ end -}}
    {{- tuple $envAll $host | include "utils.bigip_url"}}: {{ $guest_name }}
    {{- $_ := set $local "first" false -}}
{{- end -}}
{{- end }}
