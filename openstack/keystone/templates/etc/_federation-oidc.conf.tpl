{{- if .Values.federation.oidc.enabled }}

OIDCClaimDelimiter ;
OIDCClaimPrefix "OIDC-"
OIDCResponseType "id_token"
OIDCXForwardedHeaders X-Forwarded-Host X-Forwarded-Proto
# List of attributes that the user will authorize the Identity Provider to send to the Service Provider
OIDCScope "openid email profile"
OIDCProviderMetadataURL "https://{{ .Values.federation.oidc.provider }}/.well-known/openid-configuration"
OIDCOAuthVerifyJwksUri "https:///{{ .Values.federation.oidc.provider }}/oauth2/certs"
# Data (client_id and secret) of the Client created in the IdP
OIDCClientID "{{ .Values.federation.oidc.client_id | include "resolve_secret_urlquery" }}"
OIDCClientSecret "{{ .Values.federation.oidc.client_secret | include "resolve_secret_urlquery" }}"

# mod_auth_oidc internal data protection (no effect on the client)
OIDCPKCEMethod "S256"
OIDCCryptoPassphrase "{{ .Values.federation.oidc.crypto_passphrase | include "resolve_secret_urlquery" }}"
OIDCAuthRequestParams idp=#

# vanity URL that must point to a protected path that does not have any content, such as an extension of the protected federated auth path.
# you should use it as a redirect_uri in the IDP
OIDCRedirectURI "https://{{ .Values.services.public.host }}.{{ .Values.global.region }}.{{ .Values.global.tld }}/v3/auth/OS-FEDERATION/websso/openid"

{{- end }}
