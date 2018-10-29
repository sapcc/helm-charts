user  nginx;
worker_processes  1;

error_log  /dev/stdout warn;
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

    access_log  /dev/stdout  main;
    sendfile        on;
    keepalive_timeout  65;

    server {
    	listen {{ .Values.nginx.port.public }} default_server;
    
    	server_name _;

      location /public {
        allow all;
        proxy_pass http://127.0.0.1:{{ .Values.grafana.port.public }};
      }

      location ~ /(api|d) {
        proxy_set_header Authorization "Basic {{ printf "%s:%s" .Values.grafana.local.user .Values.grafana.local.password | b64enc }}";
        proxy_pass http://127.0.0.1:{{ .Values.grafana.port.public }};
      }
    }
}
