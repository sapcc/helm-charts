{{- define "octavia_worker_secret" -}}
{{- $envAll := index . 0 -}}
{{- $lb_name := index . 1 -}}
{{- $loadbalancer := index . 2 -}}
[f5_agent]
bigip_urls = {{ if $loadbalancer.devices -}}{{- tuple $envAll $loadbalancer.devices | include "utils.bigip_urls" -}}{{- else -}}{{ $loadbalancer.bigip_urls | join ", " }}{{- end }}
{{- end }}
{{- end }}
