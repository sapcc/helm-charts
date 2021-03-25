{{- define "haproxy.cfg" -}}
{{- $cluster := index . 0 -}}
{{- $context := index . 1 -}}
{{- $upstream := index . 2 -}}
global
  log stdout format raw local0 info
  zero-warning

  maxconn 2000

  #https://ssl-config.mozilla.org/#server=haproxy&version=2.1&config=intermediate&openssl=1.1.1d&guideline=5.6
  ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
  ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
  ssl-default-bind-options prefer-client-ciphers no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets
  ssl-dh-param-file /usr/local/etc/haproxy/dhparam.pem

defaults
  log global
  log-format "%ci:%cp [%tr] %ft %b/%s %TR/%Tw/%Tc/%Tr/%Ta %{+Q}r %ST %B %CC %CS %tsc %ac/%fc/%bc/%sc retries:%rc %sq/%bq %hr %hs"

  mode http
  option forwardfor
  retries 3
  retry-on all-retryable-errors

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

  acl s3 hdr_beg(x-amz-date) -m found
  capture request header User-Agent len 64
  capture response header X-Openstack-Request-Id len 64

  default_backend swift_proxy
  use_backend swift_proxy_s3 if s3

frontend api-http
  bind *:80
  monitor-uri /haproxy_test

  {{- $allowed := join " or " $cluster.sans_http }}
  {{ range $index, $san := $cluster.sans_http -}}
  acl {{ $san }} hdr(host) -i {{ $san }}.{{$context.global.region}}.{{$context.global.tld}}:{{ $cluster.proxy_public_http_port }}
  {{- end }}

  http-request redirect scheme https code 301 {{- if $allowed}} unless {{ $allowed }}
  use_backend swift_proxy if {{ $allowed }}
  {{- end }}

# We have two separate backends with identical configuration, in order to
# be able to distinguish S3-API requests from Swift-API requests in Prometheus
# metrics. (The backend name shows up as a metric label.)

backend swift_proxy
  option http-server-close

  server swift-svc {{ $upstream }}:8080

backend swift_proxy_s3
  option http-server-close

  server swift-svc {{ $upstream }}:8080

{{ end }}
