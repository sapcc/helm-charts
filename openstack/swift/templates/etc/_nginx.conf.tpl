{{- define "nginx.conf" -}}
{{- $cluster := index . 0 -}}
{{- $context := index . 1 -}}
# this is based on the default nginx.conf from the default docker hub nginx container

user  nginx;
worker_processes  4;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr:$remote_port - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for" '
                      'connection=$connection connection_requests=$connection_requests '
                      'content_length=$content_length request_length=$request_length '
                      'request_time=$request_time';

    access_log  /var/log/nginx/access.log  main;

    keepalive_timeout     {{ $context.client_timeout }};
    client_body_timeout   {{ $context.client_timeout }};
    client_header_timeout {{ $context.client_timeout }};

    # non default - default was: not set
    tcp_nopush            on;
    tcp_nodelay           on;
    types_hash_max_size   2048;

    {{- if $cluster.rate_limit_connections }}
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;
    {{- end }}
    {{- if $cluster.rate_limit_requests }}
    limit_req_zone $binary_remote_addr zone=req_limit:10m rate={{ $cluster.rate_limit_requests }}r/s;
    {{- end }}

    server {
        # TODO http/2 support
        # This could not be enabled as there were issues with high latency connections
        # and large file downloads
        #listen 443 default_server ssl http2;
        listen 443 default_server ssl;
        server_name {{tuple $cluster $context | include "swift_endpoint_host"}};
        ssl on;

        ssl_certificate     /etc/nginx/ssl/tls.crt;
        ssl_certificate_key /etc/nginx/ssl/tls.key;
        ssl_session_timeout 5m;
        ssl_session_cache   shared:SSL:50m;

        # secure cipher suites according to https://wiki.mozilla.org/Security/Server_Side_TLS
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_dhparam   /etc/nginx/dhparam.pem;
        ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';
        ssl_prefer_server_ciphers on;

        {{ tuple $cluster $context | include "swift_nginx_ratelimit" | indent 8 }}
        {{ tuple $context | include "swift_nginx_location" | indent 8 }}
    }

    # Only allow non ssl for allowed sans, otherwise redirect
    server {
        listen 80 default_server;
        server_name {{tuple $cluster $context | include "swift_endpoint_host"}};
        return 301 https://$host$request_uri; # Redirect to https
    }

    {{- range $index, $san := $cluster.sans_http }}
    server {
        # TODO http/2 support
        # This could not be enabled as there were issues with high latency connections
        # and large file downloads
        #listen 80 http2;
        listen 80;
        server_name {{$san}}.{{$context.global.region}}.{{$context.global.tld}};
        {{ tuple $cluster $context | include "swift_nginx_ratelimit" | indent 8 }}
        {{ tuple $context | include "swift_nginx_location" | indent 8 }}
    }
    {{- end }}

    # Healthcheck for Nginx, nothing else
    server {
        listen 1080 default_server;

        location /nginx-health {
            access_log off;
            return 200 "healthy\n";
        }
    }
}
{{end}}
