{{- define "f5_agent_conf_ini" -}}
{{- $envAll := index . 0 -}}
{{- $loadbalancer := index . 1 -}}
[DEFAULT]
host = {{ $loadbalancer.name }}
rpc_response_timeout = 300

[F5]
physical_device_mappings = {{ $loadbalancer.physical_device_mappings }}
sync_interval = {{ $envAll.Values.new_f5.periodic_interval }}
cleanup = {{ $envAll.Values.new_f5.cleanup | default "false" }}
migration = {{ $envAll.Values.new_f5.migration | default "false" }}
backend = icontrol
devices = {{ range $i, $host := $loadbalancer.hosts }}
{{- tuple $host ( $loadbalancer.username | default $envAll.Values.global.bigip_user ) ( $loadbalancer.password | default $envAll.Values.global.bigip_password ) | include "f5_url" }}
{{- if lt $i (sub (len $loadbalancer.hosts) 1) }}, {{ end -}}
{{- end }}

[F5_VCMP]
{{- if $loadbalancer.username }}
username = {{ required "Missing loadbalancer username!" $loadbalancer.username }}
password = {{ required "Missing loadbalancer password!" $loadbalancer.password }}
hosts_guest_mappings = {{ $loadbalancer.vcmp_host_guest_mapping | join ", " }}
{{- else }}
devices = {{ tuple $envAll ( keys $loadbalancer.vcmp_host_guest_mapping ) | include "utils.bigip_urls" }}
{{- $local := dict "first" true }}
hosts_guest_mappings = {{ range $vcmp_host, $vcmp_guest_name := $loadbalancer.vcmp_host_guest_mapping }}
    {{- if not $local.first -}}, {{ end -}}
    {{ $vcmp_host }}: {{ $vcmp_guest_name }}
    {{- $_ := set $local "first" false -}}
    {{- end }}
{{- end -}}
{{- end -}}
