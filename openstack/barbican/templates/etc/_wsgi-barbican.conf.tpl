{{- define "wsgi_barbican_conf" }}
ErrorLog /dev/stderr

LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %h %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %{X-Forwarded-For}i %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" proxy

SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
CustomLog /dev/stdout combined env=!forwarded
CustomLog /dev/stdout proxy env=forwarded

WSGIDaemonProcess barbican-api processes={{ .Values.api.processes | default 4 }} threads={{ .Values.api.threads | default 1 }} \
    user=barbican group=barbican display-name=%{GROUP}

{{- if .Values.tls.enabled }}
Listen 0.0.0.0:{{ .Values.tls.httpsPort }}

<VirtualHost *:{{ .Values.tls.httpsPort }}>
    ServerName {{ include "barbican_api_endpoint_host_public" . }}

    SSLEngine on
    SSLCertificateFile /etc/barbican/tls/tls.crt
    SSLCertificateKeyFile /etc/barbican/tls/tls.key

    Include /etc/apache2/conf-enabled/tls-hardening.conf

    WSGIProcessGroup barbican-api
    WSGIScriptAlias / /var/www/cgi-bin/barbican/barbican-wsgi-api
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LimitRequestBody 114688

    <Directory /var/www/cgi-bin/barbican>
        Require all granted
    </Directory>

    ErrorLog /dev/stderr
    SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
    CustomLog /dev/stdout combined env=!forwarded
    CustomLog /dev/stdout proxy env=forwarded

    KeepAliveTimeout 61
</VirtualHost>
{{- end }}

Listen 0.0.0.0:{{ .Values.api_port_internal }}

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
    SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
    CustomLog /dev/stdout combined env=!forwarded
    CustomLog /dev/stdout proxy env=forwarded

    KeepAliveTimeout 61
</VirtualHost>
{{- end }}