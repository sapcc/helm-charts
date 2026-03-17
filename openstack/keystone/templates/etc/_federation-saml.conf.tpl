{{- define "keystone.federation-saml.conf" -}}
#
# Apache mod_shib configuration for SAML 2.0 federation
# Protects the OS-FEDERATION endpoints with Shibboleth authentication
#

# Ensure mod_shib is loaded
<IfModule !mod_shib>
    LoadModule mod_shib /usr/lib/apache2/modules/mod_shib.so
</IfModule>

# Shibboleth handler endpoint (required by mod_shib)
<Location /Shibboleth.sso>
    SetHandler shib
</Location>

# Per-tenant federated authentication endpoints
{{- range $tenant := $.Values.federation.saml.idp.tenants }}

# Tenant: {{ $tenant.name }} (IdP: {{ $tenant.entityId }})
<Location /v3/OS-FEDERATION/identity_providers/{{ $tenant.name }}/protocols/mapped/auth>
    AuthType shibboleth
    ShibRequestSetting requireSession 1
    ShibRequestSetting entityID {{ $tenant.entityId }}
    ShibUseHeaders Off
    Require valid-user
</Location>

<Location /v3/auth/OS-FEDERATION/identity_providers/{{ $tenant.name }}/protocols/mapped/websso>
    AuthType shibboleth
    ShibRequestSetting requireSession 1
    ShibRequestSetting entityID {{ $tenant.entityId }}
    ShibUseHeaders Off
    Require valid-user
</Location>
{{- end }}
{{- end -}}
