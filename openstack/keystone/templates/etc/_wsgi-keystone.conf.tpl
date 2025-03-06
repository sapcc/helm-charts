# Copyright 2017 The Openstack-Helm Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Listen 0.0.0.0:5000

ErrorLog /dev/stdout

LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %h %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%{%Y-%m-%d %T}t.%{msec_frac}t %{pid}P INFO apache \"%{X-Openstack-Request-ID}i\" %{X-Forwarded-For}i %l %u \"%r\" %>s %b %{ms}T \"%{Referer}i\" \"%{User-Agent}i\"" proxy

SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
CustomLog /dev/stdout combined env=!forwarded
CustomLog /dev/stdout proxy env=forwarded

{{- if .Values.federation.oidc.enabled }}

OIDCSSLValidateServer Off
OIDCOAuthSSLValidateServer Off
OIDCCookieSameSite On

OIDCClaimDelimiter ;
OIDCClaimPrefix "OIDC-"
OIDCResponseType "id_token"
OIDCXForwardedHeaders X-Forwarded-Host X-Forwarded-Proto
# List of attributes that the user will authorize the Identity Provider to send to the Service Provider
OIDCScope "openid email profile"
OIDCProviderMetadataURL "https://{{ .Values.federation.oidc.provider }}/.well-known/openid-configuration"
OIDCOAuthVerifyJwksUri "https:///{{ .Values.federation.oidc.provider }}/oauth2/certs"
# Data (client_id and secret) of the Client created in the IdP
OIDCClientID "{{ .Values.federation.oidc.client_id }}"
OIDCClientSecret "{{ .Values.federation.oidc.client_secret }}"

# mod_auth_oidc internal data protection (no effect on the client)
OIDCPKCEMethod "S256"
OIDCCryptoPassphrase "{{ .Values.federation.oidc.crypto_passphrase }}"
OIDCAuthRequestParams idp=#

# vanity URL that must point to a protected path that does not have any content, such as an extension of the protected federated auth path.
# you should use it as a redirect_uri in the IDP
OIDCRedirectURI "https://{{ .Values.services.public.host }}.{{ .Values.global.region }}.{{ .Values.global.tld }}/v3/auth/OS-FEDERATION/websso/openid"

# IDP Endpoint for token validation


<Location "/v3/auth/OS-FEDERATION/websso/openid">
    AuthType "openid-connect"
    Require valid-user
</Location>

<Location "/v3/auth/OS-FEDERATION/identity_providers/sap-ias/protocols/openid/websso">
    AuthType "openid-connect"
    Require valid-user
</Location>

<Location "/v3/auth/OS-FEDERATION/identity_providers/sap-ias/protocols/openid/auth">
    AuthType "openid-connect"
    Require valid-user
</Location>

# Location a non-browser apps can communicate with
<Location ~ "/v3/OS-FEDERATION/identity_providers/sap-ias/protocols/openid/auth">
    # AuthType here is not "openid-connect" since apps going here do not support browser flow
    AuthType "auth-openidc"
    Require valid-user
</Location>

{{- end }}

<VirtualHost *:5000>
    ServerName {{ .Values.services.public.host }}.{{ .Values.global.region }}.{{ .Values.global.tld }}
    WSGIDaemonProcess keystone-public processes=8 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /var/www/cgi-bin/keystone/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LimitRequestBody 114688
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    ErrorLog /dev/stdout

    SetEnvIf X-Forwarded-For "^.*\..*\..*\..*" forwarded
    CustomLog /dev/stdout combined env=!forwarded
    CustomLog /dev/stdout proxy env=forwarded

    KeepAliveTimeout 61
</VirtualHost>

Alias /identity /var/www/cgi-bin/keystone/keystone-wsgi-public
<Location /identity>
    SetHandler wsgi-script
    Options +ExecCGI

    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
</Location>
