# Apache WSGI configuration for Barbican API
# WP-1187: Migrate to Apache+mod_wsgi
# WP-1188: Add TLS Termination to Apache
# Based on Keystone's wsgi-keystone.conf pattern

{{- define "wsgi_barbican_conf" }}
# Error and access logging
ErrorLog /dev/stderr

LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %h %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %{X-Forwarded-For}i %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" proxy

SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
CustomLog /dev/stdout combined env=!forwarded
CustomLog /dev/stdout proxy env=forwarded

{{- if .Values.tls.enabled }}
# =============================================================================
# HTTPS VirtualHost (External traffic via TLS passthrough)
# WP-1188: TLS Termination at Apache
# =============================================================================
Listen 0.0.0.0:{{ .Values.tls.httpsPort }}

<VirtualHost *:{{ .Values.tls.httpsPort }}>
    ServerName {{ include "barbican_api_endpoint_host_public" . }}

    # TLS Configuration
    SSLEngine on
    SSLCertificateFile /etc/barbican/tls/tls.crt
    SSLCertificateKeyFile /etc/barbican/tls/tls.key

    # Include TLS hardening configuration (WP-1196)
    Include /etc/apache2/conf-enabled/tls-hardening.conf

    # WSGI Configuration (using Keystone-style path)
    WSGIDaemonProcess barbican-api-https processes={{ .Values.api.processes | default 4 }} threads={{ .Values.api.threads | default 1 }} \
        user=barbican group=barbican display-name=%{GROUP}
    WSGIProcessGroup barbican-api-https
    WSGIScriptAlias / /var/www/cgi-bin/barbican/barbican-wsgi-api
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On

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

# =============================================================================
# HTTP VirtualHost (Internal traffic protected by Linkerd mTLS)
# WP-1197: Linkerd mTLS Enforcement - Port {{ .Values.api_port_internal }} continues with Linkerd mTLS
# =============================================================================
Listen 0.0.0.0:{{ .Values.api_port_internal }}

<VirtualHost *:{{ .Values.api_port_internal }}>
    ServerName {{ include "barbican_api_endpoint_host_public" . }}

    # WSGI Configuration (using Keystone-style path)
    WSGIDaemonProcess barbican-api-http processes={{ .Values.api.processes | default 4 }} threads={{ .Values.api.threads | default 1 }} \
        user=barbican group=barbican display-name=%{GROUP}
    WSGIProcessGroup barbican-api-http
    WSGIScriptAlias / /var/www/cgi-bin/barbican/barbican-wsgi-api
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On

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