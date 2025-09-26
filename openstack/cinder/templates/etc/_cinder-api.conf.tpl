{{- $conf := index . 1 -}}
{{- with index . 0 -}}
[DEFAULT]
{{- if not $conf.use_uwsgi }}
osapi_volume_workers = {{ $conf.workers }}
wsgi_default_pool_size = {{ $conf.wsgi_default_pool_size | default .Values.global.wsgi_default_pool_size | default 100 }}
{{- end }}
{{- end }}
