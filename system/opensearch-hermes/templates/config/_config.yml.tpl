---
_meta:
  type: "config"
  config_version: 2

config:
  dynamic:
    kibana:
      server_username: {{ .Values.global.users.kibanaserver2.username_resolve }}
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
              pemtrustedcas_filepath: {{.Values.auth.ca_path }}
        authentication_backend:
          type: noop

er" (class org.opensearch.security.securityconf.impl.v7.ConfigV7$Dynamic), not marked as ignorable (16 known properties: "on_behalf_of", "license", "disable_intertransport_auth", "http", "kibana", "authz", "auth_failure_listeners", "transport_userrname_attribute", "filtered_alias_mode", "authc", "disable_rest_auth", "respect_request_indices_options", "multi_rolespan_enabled", "do_not_fail_on_forbidden", "hosts_resolver_mode", "do_not_fail_on_forbidden_empty"])
