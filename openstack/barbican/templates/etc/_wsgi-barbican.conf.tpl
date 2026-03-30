{{- define "wsgi_barbican_conf" }}
ServerName {{ include "barbican_api_endpoint_host_public" . }}
{{- if .Values.use_json }}
ErrorLog /dev/stdout
ErrorLogFormat "%M"
LogFormat "{\"timestamp\":\"%{%Y-%m-%dT%H:%M:%S}t.%{msec_frac}t\",\"pid\":%{pid}P,\"levelname\":\"INFO\",\"name\":\"apache.access\",\"request_id\":\"%{X-Openstack-Request-ID}i\",\"client_ip\":\"%a\",\"method\":\"%m\",\"uri\":\"%U%q\",\"protocol\":\"%H\",\"status\":%>s,\"bytes_sent\":%B,\"duration_ms\":%{ms}T,\"referer\":\"%{Referer}i\",\"user_agent\":\"%{User-Agent}i\"}" json_combined
LogFormat "{\"timestamp\":\"%{%Y-%m-%dT%H:%M:%S}t.%{msec_frac}t\",\"pid\":%{pid}P,\"levelname\":\"INFO\",\"name\":\"apache.access\",\"request_id\":\"%{X-Openstack-Request-ID}i\",\"client_ip\":\"%{X-Forwarded-For}i\",\"method\":\"%m\",\"uri\":\"%U%q\",\"protocol\":\"%H\",\"status\":%>s,\"bytes_sent\":%B,\"duration_ms\":%{ms}T,\"referer\":\"%{Referer}i\",\"user_agent\":\"%{User-Agent}i\"}" json_proxy
SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
CustomLog /dev/stdout json_combined env=!forwarded
CustomLog /dev/stdout json_proxy env=forwarded
{{- else }}
ErrorLog /dev/stderr
LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %h %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %{X-Forwarded-For}i %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" proxy
SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
CustomLog /dev/stdout combined env=!forwarded
CustomLog /dev/stdout proxy env=forwarded
{{- end }}

WSGIDaemonProcess barbican-api processes={{ .Values.api.processes | default 1 }} threads={{ .Values.api.threads | default 1 }} \
    user=barbican group=barbican display-name=%{GROUP}

Listen 0.0.0.0:{{ .Values.api_port_internal }}

{{- if .Values.tls.enabled }}
# TLS hardening at server level (must be outside VirtualHost)
Include /etc/apache2/conf-enabled/tls-hardening.conf

# External HTTPS endpoint (via Ingress TLS passthrough)
Listen 0.0.0.0:443

# TLS hardening at server level (must be outside VirtualHost)
Include /etc/apache2/conf-enabled/tls-hardening.conf

<VirtualHost *:443>
    SSLEngine on
    SSLCertificateFile /mnt/secrets/tls.crt
    SSLCertificateKeyFile /mnt/secrets/tls.key

    WSGIDaemonProcess barbican-api-tls processes={{ .Values.api.processes | default 1 }} threads=1 user=barbican group=barbican display-name=%{GROUP}
    WSGIProcessGroup barbican-api-tls
    WSGIScriptAlias / /var/www/cgi-bin/barbican/barbican-wsgi-api
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On

    <IfVersion >= 2.4>
        ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    ErrorLog /dev/stderr

    KeepAliveTimeout 61
</VirtualHost>
{{- end }}

# Internal HTTP endpoint (protected by Linkerd mTLS at the network layer)
<VirtualHost *:{{ .Values.api_port_internal }}>
    ServerName {{ include "barbican_api_endpoint_host_public" . }}

    WSGIProcessGroup barbican-api
    WSGIScriptAlias / /var/www/cgi-bin/barbican/barbican-wsgi-api
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LimitRequestBody 114688

    <Directory /var/www/cgi-bin/barbican>
        Require all granted
    </Directory>

    ErrorLog /dev/stderr
    {{- if .Values.use_json }}
    SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
    CustomLog /dev/stdout json_combined env=!forwarded
    CustomLog /dev/stdout json_proxy env=forwarded
    {{- else }}
    SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
    CustomLog /dev/stdout combined env=!forwarded
    CustomLog /dev/stdout proxy env=forwarded
    {{- end }}

    KeepAliveTimeout 61
</VirtualHost>
{{- end }}
