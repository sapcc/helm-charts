{{- define "updates-proxy.conf" -}}
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
  }

}
{{- end }}
{{- end -}}
