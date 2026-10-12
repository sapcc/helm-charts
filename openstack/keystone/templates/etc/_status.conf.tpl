LoadModule status_module /usr/lib/apache2/modules/mod_status.so

<IfModule mod_status.c>
    <Location /server-status>
        SetHandler server-status
        Require ip 127.0.0.1
    </Location>
    ExtendedStatus On
</IfModule>
