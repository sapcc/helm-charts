{{- define "updates-proxy.conf" -}}
proxy_cache_path /nginx-cache keys_zone=my_cache:1m max_size=1g inactive=60m use_temp_path=off;
{{- range $channel := .Values.updatesProxy.channels -}}
server {
  listen       80;
  server_name  {{ $channel.name }} default;

  location / {
    proxy_buffering off;
    proxy_ssl_verify_depth 0;
    proxy_pass {{ $.Values.updatesProxy.storageUrl | trimSuffix "/" }}/{{ $channel.container }}/;
    proxy_redirect ~^https?://{{ $.Values.updatesProxy.storageUrl | trimSuffix "/" | trimPrefix "https://" | trimPrefix "http://"}}/{{ $channel.container }}/(.*)$ /$1;
    proxy_set_header X-Forwarded-For        $proxy_add_x_forwarded_for;

    proxy_cache my_cache;
    proxy_cache_revalidate on;
    proxy_cache_lock on;
    proxy_cache_valid 200 10m;
    proxy_cache_any any 0;
  }

}
{{ end }}
{{- end -}}
