{{- define "share_netapp_conf_secret" -}}
{{- $context := index . 0 -}}
{{- range $i, $share := $context.Values.global.netapp.filers }}

[{{$share.name}}]
netapp_login={{$share.username}}
netapp_password={{$share.password}}

{{- end -}}
{{- end }}
