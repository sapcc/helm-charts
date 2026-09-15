# Defines configuration options specific for Arista ML2 Mechanism driver

[ml2_arista]
{{- range $k,$v := .Values.arista }}
  {{- if and (ne "switches" $k) (ne "physnet" $k) (ne "disable_sec_group_support_on_device_ids" $k) }}
{{ $k }} = {{ $v }}
  {{- end }}
{{- end }}
{{- if .Values.arista.physnet }}
managed_physnets = {{ required "A valid .Values.arista required!" .Values.arista.physnet }}
{{- end }}
coordinator_url = memcached://neutron-memcached.{{ include "svc_fqdn" . }}:{{ .Values.memcached.memcached.port }}

region_name = {{ .Values.global.region }}
{{- if .Values.arista.disable_sec_group_support_on_device_ids }}
disable_sec_group_support_on_device_ids = {{ .Values.arista.disable_sec_group_support_on_device_ids | join "," }}
{{- end }}
