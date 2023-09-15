---
_meta:
  type: "config"
  config_version: 2

config:
  dynamic:
    http:
      anonymous_auth_enabled: false
      xff:
        enabled: false
    authc:
      basic_internal_auth_domain:
        description: "Authenticate via HTTP Basic against internal users database"
        http_enabled: true
        transport_enabled: true
        order: 1
        http_authenticator:
          type: basic
          challenge: false
        authentication_backend:
          type: intern
      openid_auth_domain:
        order: 2
        http_enabled: true
        transport_enabled: false
        http_authenticator:
          type: openid
          challenge: true
          config:
            subject_key: name
            roles_key: roles
            openid_connect_url: {{.Values.auth.provider }}
            enable_ssl: true
            openid_connect_idp:
              enable_ssl: true
              pemtrustedcas_filepath: /usr/share/opensearch/config/certs/tenant/opensearchCA.crt
        authentication_backend:
          type: noop
