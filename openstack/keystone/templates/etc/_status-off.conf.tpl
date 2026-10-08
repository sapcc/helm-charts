{{/*
Neutralize mod_status: it is enabled by default in the image and ships a
status.conf that exposes /server-status with ExtendedStatus On. This override
is parsed after mods-enabled, so it wins.
*/}}

<IfModule mod_status.c>
    ExtendedStatus Off
    <Location "/server-status">
        SetHandler none
        Require all denied
    </Location>
</IfModule>
