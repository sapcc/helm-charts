{{/*
Apache WSGI configuration for Barbican API.
Replaces paste.httpserver with Apache+mod_wsgi for production serving.
*/}}

Listen 0.0.0.0:{{ .Values.api_port_internal }}

ErrorLog /dev/stderr

LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %h %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %{X-Forwarded-For}i %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" proxy

SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
CustomLog /dev/stdout combined env=!forwarded
CustomLog /dev/stdout proxy env=forwarded

<VirtualHost *:{{ .Values.api_port_internal }}>
    WSGIDaemonProcess barbican-api processes={{ .Values.api.processes | default 4 }} threads=1 user=barbican group=barbican display-name=%{GROUP}
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
