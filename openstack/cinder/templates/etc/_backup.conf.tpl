{{- define "backup_conf" -}}
{{- $volume := index . 1 -}}
{{- with index . 0 -}}

[DEFAULT]
host = cinder-backup-{{$volume.availability_zone}}
storage_availability_zone = {{$volume.region}}{{$volume.availability_zone}}

[{{$volume.availability_zone}}]
{{range $key, $value := $volume -}}
{{- if and (ne $key "availability_zone") (ne $key "region")}}
{{$key}}={{$value | quote}}
{{- end}}
{{- end -}}
{{- end -}}
{{- end -}}
