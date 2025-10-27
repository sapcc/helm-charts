{{- define "haproxy.cfg" -}}
global
  # Drop privileges after root started haproxy (user:haproxy / group:haproxy)
  uid 99
  gid 99

  log stdout format raw local0 {{ .Values.default_log_level }}
  zero-warning

  maxconn 2000

  # TODO: Should be replaced by https://ssl-config.mozilla.org/#server=haproxy&version=2.3&config=intermediate&openssl=1.1.1d&guideline=5.6
  # AES256-SHA256 seems to be needed for iPXE with tlsv1.2

  # https://ssl-config.mozilla.org/#server=haproxy&version=2.3&config=old&openssl=1.1.1d&guideline=5.6
  # old configuration - this is for backward compatibility with nginx based deplyoments and poor clients like iPXE
  ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA
  ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
  ssl-default-bind-options no-sslv3 no-tls-tickets
  ssl-dh-param-file /usr/local/etc/haproxy/dhparam.pem

defaults
  log global
  log-format "%ci:%cp [%tr] %ft %b/%s %TR/%Tw/%Tc/%Tr/%Ta/%U %{+Q}r %ST %B %CC %CS %tsc %ac/%fc/%bc/%sc retries:%rc %sq/%bq %hr %hs"

  mode http
  option forwardfor
  retries 3
  retry-on all-retryable-errors
  option redispatch

  timeout connect 10s
  timeout client {{ add .Values.client_timeout 5 }}s
  timeout server {{ add .Values.client_timeout .Values.node_timeout 5 }}s

listen stats
  bind *:8404
  http-request use-service prometheus-exporter if { path /metrics }
  stats enable
  stats uri /stats
  stats refresh 10s

frontend api
  maxconn 1800
  bind *:443 ssl crt /usr/local/etc/haproxy/ssl/tls.pem

  acl s3 hdr_beg(x-amz-date) -m found
  capture request header User-Agent len 64
  capture response header X-Openstack-Request-Id len 64

  default_backend swift_proxy
  use_backend swift_proxy_s3 if s3

frontend api-http
  bind *:80
  monitor-uri /haproxy_test

  {{- $allowed := join " or " .Values.sans_http }}
  {{- range $index, $san := .Values.sans_http }}
  acl {{ $san }} hdr(host) -i {{ $san }}.{{ $.Values.global.region }}.{{ $.Values.global.tld }}:{{ $.Values.proxy_public_http_port }}
  {{- end }}

  http-request redirect scheme https code 301 {{- if $allowed}} unless {{ $allowed }}
  use_backend swift_proxy if {{ $allowed }}
  {{- end }}

# We have two separate backends with identical configuration, in order to
# be able to distinguish S3-API requests from Swift-API requests in Prometheus
# metrics. (The backend name shows up as a metric label.)

backend swift_proxy
{{- include "swift_haproxy_backend" . | nindent 2 }}

backend swift_proxy_s3
  # No retries on 503, which is the rate limit repsonse from S3
  retry-on conn-failure empty-response junk-response response-timeout 0rtt-rejected 500 502 504
{{- include "swift_haproxy_backend" . | nindent 2 }}

{{- end }}
