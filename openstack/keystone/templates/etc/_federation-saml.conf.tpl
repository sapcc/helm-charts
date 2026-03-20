{{- define "keystone.federation-saml.conf" -}}
#
# Apache mod_shib configuration for SAML 2.0 federation
# Protects the OS-FEDERATION endpoints with Shibboleth authentication
# Each tenant uses its own ApplicationOverride (per-tenant SP key pair)
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
# ShibRequestSetting applicationId selects the per-tenant ApplicationOverride
# in shibboleth2.xml, which has the tenant-specific SP key and IdP metadata.
{{- range $tenant := $.Values.federation.saml.idp.tenants }}

# Tenant: {{ $tenant.name }} (IdP: {{ $tenant.entityId }})
<Location /v3/OS-FEDERATION/identity_providers/{{ $tenant.name }}/protocols/saml2/auth>
    AuthType shibboleth
    ShibRequestSetting requireSession 1
    ShibRequestSetting applicationId {{ $tenant.name }}
    ShibRequestSetting entityID {{ $tenant.entityId }}
    ShibUseHeaders Off
    Require valid-user
</Location>

<Location /v3/auth/OS-FEDERATION/identity_providers/{{ $tenant.name }}/protocols/saml2/websso>
    AuthType shibboleth
    ShibRequestSetting requireSession 1
    ShibRequestSetting applicationId {{ $tenant.name }}
    ShibRequestSetting entityID {{ $tenant.entityId }}
    ShibUseHeaders Off
    Require valid-user
</Location>
{{- end }}
{{- end -}}
