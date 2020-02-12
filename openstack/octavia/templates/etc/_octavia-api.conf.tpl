Listen 0.0.0.0:{{.Values.api_port_internal}}

ErrorLog /dev/stdout

LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %h %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %{X-Forwarded-For}i %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" proxy

SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
CustomLog /dev/stdout combined env=!forwarded
CustomLog /dev/stdout proxy env=forwarded

<VirtualHost *:{{.Values.api_port_internal}}>

    WSGIDaemonProcess octavia-wsgi user=octavia group=octavia processes=8 threads=1 display-name=%{GROUP}
    WSGIProcessGroup octavia-wsgi
    WSGIScriptAlias / /var/lib/openstack/bin/octavia-wsgi
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On

    ErrorLog /dev/stdout
    SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
    CustomLog /dev/stdout combined env=!forwarded
    CustomLog /dev/stdout proxy env=forwarded

    <Directory /var/lib/openstack/bin/>
        WSGIProcessGroup octavia-wsgi
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>

</VirtualHost>
