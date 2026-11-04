{{/*
Server-level Apache hardening: suppress the version banner, disable the TRACE
method, and turn off directory listing for the document root. Parsed after the
packaged apache2.conf so these directives take precedence.
*/}}

# Suppress server version banner and disable TRACE
ServerTokens Prod
ServerSignature Off
TraceEnable Off

# Disable directory listing for the document root
<Directory /var/www/>
    Options FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
