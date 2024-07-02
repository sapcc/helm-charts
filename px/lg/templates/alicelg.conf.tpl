{{- define "alicelg_conf" -}}
{{- $region := index . 0 -}}
# Routeservers
#{{- range $i, $domain := list "1" "2" -}}
{{- range $i, $domain := list "1" -}}
{{- range $service := list "1" "2" "3" -}}
{{- range $instance := list "1" "2" -}}
{{- $deployment_name := printf "%s-pxrs-%s-s%s-%s" $region $domain $service $instance -}}
[source.{{ $deployment_name }}]
name = {{ $deployment_name }}
group = Service {{$service}}
#blackholes = 1.1.1.1, 2.2.2.2

[source.{{ $deployment_name }}.birdwatcher]
api = http://{{ $deployment_name }}:29184
type = single_table

{{- if eq $service "3" }}
main_table = VPN4_S{{ $service}};
{{- else }}
main_table = IPV4_S{{ $service}};
{{- end }}
# Timeout in seconds to wait for the status data (only required if enable_neighbors_status_refresh is true)
neighbors_refresh_timeout = 2
show_last_reboot = true

{{ end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end }}
