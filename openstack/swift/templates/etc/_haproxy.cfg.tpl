{{- define "haproxy.cfg" -}}
{{- $cluster := index . 0 -}}
{{- $context := index . 1 -}}
{{- $upstream := index . 2 -}}
global
  log stdout format raw local0 info

  maxconn 2000

  #https://ssl-config.mozilla.org/#server=haproxy&version=2.1&config=intermediate&openssl=1.1.1d&guideline=5.6
  ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
  ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
  ssl-default-bind-options prefer-client-ciphers no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets
  ssl-dh-param-file /usr/local/etc/haproxy/dhparam.pem

defaults
  log global
  log-format "[%tr] %ci:%cp %ft %b/%s %TR/%Tw/%Tc/%Tr/%Ta %{+Q}r %ST %B %CC %CS %tsc %ac/%fc/%bc/%sc/%rc %sq/%bq %hr %hs"

  mode http
  option forwardfor
  retries 3

  timeout connect 10s
  timeout client {{ add $context.client_timeout 5 }}s
  timeout server {{ add $context.client_timeout $context.node_timeout 5 }}s

listen stats
  bind *:8404
  option http-use-htx
  http-request use-service prometheus-exporter if { path /metrics }
  stats enable
  stats uri /stats
  stats refresh 10s

frontend api
  bind *:443 ssl crt /usr/local/etc/haproxy/ssl/tls.pem

  default_backend swift_proxy

frontend api-http
  bind *:80
  {{- $allowed := join " or " $cluster.sans_http }}
  {{ range $index, $san := $cluster.sans_http -}}
  acl {{ $san }} hdr(host) -i {{ $san }}.{{$context.global.region}}.{{$context.global.tld}}
  {{ end -}}

  http-request redirect scheme https code 301 {{- if $allowed}} unless {{ $allowed }}
  use_backend swift_proxy if {{ $allowed }}
  {{- end }}

backend swift_proxy
  server swift-svc {{ $upstream }}:8080

{{ end }}
