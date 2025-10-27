{{- define "octavia_worker_secret" -}}
{{- $envAll := index . 0 -}}
{{- $lb_name := index . 1 -}}
{{- $loadbalancer := index . 2 -}}

[f5_agent]
bigip_urls = {{ if $loadbalancer.devices -}}{{- tuple $envAll $loadbalancer.devices | include "utils.bigip_urls" -}}{{- else -}}{{ $loadbalancer.bigip_urls | join ", " }}{{- end }}

[networking]
{{- if $loadbalancer.vcmps }}
vcmp_urls = {{ tuple $envAll $loadbalancer.vcmps | include "utils.bigip_urls" -}}
{{- end }}
{{- if $loadbalancer.override_vcmp_guest_names }}
override_vcmp_guest_names = {{ $loadbalancer.override_vcmp_guest_names | join ", " -}}
{{- end }}

{{- end }}
