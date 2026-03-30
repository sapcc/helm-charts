{{/*
Apache WSGI configuration for Barbican API.
Replaces paste.httpserver with Apache+mod_wsgi for production serving
and enables pod-level TLS termination when tls.enabled is true.
*/}}

Listen 0.0.0.0:{{ .Values.api_port_internal }}

ErrorLog /dev/stderr

LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %h %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %{X-Forwarded-For}i %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" proxy

SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
CustomLog /dev/stdout combined env=!forwarded
CustomLog /dev/stdout proxy env=forwarded

{{- if .Values.tls.enabled }}
# TLS hardening at server level (must be outside VirtualHost)
Include /etc/apache2/conf-enabled/tls-hardening.conf

# External HTTPS endpoint (via Ingress TLS passthrough)
Listen 0.0.0.0:443

<VirtualHost *:443>
    SSLEngine on
    SSLCertificateFile /mnt/secrets/tls.crt
    SSLCertificateKeyFile /mnt/secrets/tls.key

    WSGIDaemonProcess barbican-api-tls processes={{ .Values.api.processes | default 1 }} threads=1 user=barbican group=barbican display-name=%{GROUP}
    WSGIProcessGroup barbican-api-tls
    WSGIScriptAlias / /var/lib/openstack/bin/barbican-wsgi-api
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
    WSGIDaemonProcess barbican-api processes={{ .Values.api.processes | default 1 }} threads=1 user=barbican group=barbican display-name=%{GROUP}
    WSGIProcessGroup barbican-api
    WSGIScriptAlias / /var/lib/openstack/bin/barbican-wsgi-api
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On

    <IfVersion >= 2.4>
        ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    ErrorLog /dev/stderr

    KeepAliveTimeout 61
</VirtualHost>
