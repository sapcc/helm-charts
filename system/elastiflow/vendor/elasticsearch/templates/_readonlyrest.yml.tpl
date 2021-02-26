# rbac for elasticsearch
readonlyrest:
    enable: true
    response_if_req_forbidden: <h1>Forbidden</h1>

    access_control_rules:

      # access for logstash to write to the logstash indexes
      - name: data
        actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
        indices: ["elastiflow-*"]
        auth_key: {{.Values.global.elastiflow_user}}:${ELASTIFLOW_PASSWORD}

      # admin user
      - name: Admin
        auth_key: {{.Values.global.elastiflow_admin_user}}:${ELASTIFLOW_ADMIN_PW}

      # deny access without a proper sso cert validated from the ingress - proxy definition see below
      - name: no-sso
        type: forbid
        proxy_auth:
          proxy_auth_config: "ingress"
          users: ["anonymous"]

      # if we get a user in the x-remote-user header, check if it has valid ldap groups and if: allow access - ldap definition see below
      - name: sso-and-ldap
        type: allow
        proxy_auth:
          proxy_auth_config: "ingress"
          users: ["*"]
        ldap_authorization:
          name: "ldap1"
          groups: [{{.Values.global.ldap.es_user_groups}}]

    # get the user from the x-remote-user header
    proxy_auth_configs:
    - name: ingress
      user_id_header: "X-REMOTE-USER"

    # ldap connection definition
    ldaps:
    - name: ldap1
      host: "{{ .Values.global.ldap.host }}"
      port: {{ .Values.global.ldap.port }}
      ssl_enabled: {{ .Values.global.ldap.ssl }}
      ssl_trust_all_certs: {{ .Values.global.ldap.ssl_skip_verify}}
      bind_dn: "{{.Values.global.ldap.bind_dn}},{{ .Values.global.ldap.suffix }}"
      bind_password: "${LDAP_PASSWORD}"
      search_user_base_DN: "OU=Identities,{{ .Values.global.ldap.suffix }}"
      user_id_attribute: "sAMAccountName"
      search_groups_base_DN: "{{ .Values.global.ldap.group_search_base_dns }},{{ .Values.global.ldap.suffix }}"
      unique_member_attribute: "member"
      connection_pool_size: 10
      connection_timeout_in_sec: 10
      request_timeout_in_sec: 10
      cache_ttl_in_sec: 300
