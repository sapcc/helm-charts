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

{{- if .Values.tls.enabled }}
LoadModule ssl_module /usr/lib/apache2/modules/mod_ssl.so
Listen 0.0.0.0:443
<VirtualHost *:443>
    ServerName {{ include "barbican_api_endpoint_host_public" . }}

    SSLEngine on
    SSLCertificateFile    /etc/apache2/ssl/tls.crt
    SSLCertificateKeyFile /etc/apache2/ssl/tls.key
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
{{- end }}
