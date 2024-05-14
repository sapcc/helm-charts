{{- define "asr1k_sec" -}}
{{- $config_agent := index . 1 -}}
{{- with index . 0 -}}

{{ range $i, $hosting_device := $config_agent.hosting_devices}}
[asr1k_device:{{required "A valid $hosting_device required!" $hosting_device.name}}]
user_name = {{$hosting_device.user_name | default $config_agent.user_name | required "A valid user_name must be supplied under config_agents or hosting_devices!" }}
password = {{$hosting_device.password | default $config_agent.password | required "A valid password must be supplied under config_agents or hosting_devices!" }}
{{end}}

{{- end -}}
{{- end -}}
