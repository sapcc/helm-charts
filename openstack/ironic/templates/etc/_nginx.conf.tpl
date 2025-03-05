map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

server {

    listen 443 default_server ssl http2;
    server_name  {{ include "ironic_console_endpoint_host_public" . }};
    ssl_certificate /etc/nginx/certs/tls.crt;
    ssl_certificate_key /etc/nginx/certs/tls.key;

    # https://ssl-config.mozilla.org/
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
    ssl_session_tickets off;

    ssl_dhparam /etc/nginx/conf.d/dhparam.pem;

    # intermediate configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security "max-age=63072000" always;

    # Health-Check
    location /health {
        access_log off;
        return 204;
    }

    # Possibly proxies probing the host
    location / {
        access_log off;
        return 204;
    }

    # We only need to authenticate the GET of the index, as that
    # creates a session and returns a secret used in all futher requests
    # The url is of the form:
    #   /<conductor-name>/<instance-uuid>/<expiry>/<md5-signature>/<static-resources>

    # We obviously do not have to secure any static resources
    location ~* "/[^/]*/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/([0-9]*)/([^/]*)/?$" {
        secure_link $3,$2;
        secure_link_md5 "$secure_link_expires$1 {{required "A valid .Values.console.secret required!" .Values.console.secret | include "resolve_secret" }}";

        set $check $secure_link;

        # Do not authenticate the POST, as it is handled internally
        if ($request_method = POST) {
            set $check "1";
        }

        if ($check = "" ) {
            return 403;
        }

        if ($check = "0") {
            return 410;
        }

        proxy_pass http://unix:/shellinabox/$1.sock:/;
        proxy_set_header    Host      $host;
        proxy_http_version  1.1;
        proxy_redirect      off;
        proxy_buffering     off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }

    location ~* "/[^/]*/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/([0-9]*)/([^/]*)/([^.]+\.[^.]+)$" {
        if ($request_method != GET) {
            return 400;
        }
        proxy_pass http://unix:/shellinabox/$1.sock:/$4;
        proxy_set_header    Host      $host;
        proxy_http_version  1.1;
        proxy_redirect      off;
        proxy_buffering     off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}
