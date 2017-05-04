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

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    keepalive_timeout   65;
    # non default - default was: not set
    tcp_nopush          on;
    tcp_nodelay         on;
    types_hash_max_size 2048;

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

        location / {
            # NOTE: It's imperative that the argument to proxy_pass does not
            # have a trailing slash. Swift needs to see the original request
            # URL for its domain-remap and staticweb functionalities.
            proxy_pass        http://127.0.0.1:8080;
            proxy_set_header  Host             $host;
            proxy_set_header  X-Real_IP        $remote_addr;
            proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;
            proxy_pass_header Date;

            # buffering must be disabled since GET response or PUT request bodies can be *very* large
            proxy_buffering         off;
            proxy_request_buffering off;
            client_max_body_size    0;    # Don't check request body size
        }
    }
}
{{end}}
