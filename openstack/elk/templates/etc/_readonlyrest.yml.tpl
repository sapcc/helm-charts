# rbac for elasticsearch
readonlyrest:
    enable: true
    response_if_req_forbidden: <h1>Forbidden</h1>

    access_control_rules:

    # access for logstash to write to the logstash indexes
    - name: data
      actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
      indices: ["logstash-*"]
      auth_key: {{.Values.elk_elasticsearch_data_user}}:{{.Values.elk_elasticsearch_data_password}}

    # access to write to the jump server log indexes
    - name: jump
      actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
      indices: ["jump-*"]
      auth_key: {{.Values.elk_elasticsearch_jump_user}}:{{.Values.elk_elasticsearch_jump_password}}

    - name: Monsoon (read only, but can create dashboards)
      kibana_access: ro
      auth_key: {{.Values.elk_elasticsearch_monsoon_user}}:{{.Values.elk_elasticsearch_monsoon_password}}
      indices: [".kibana", ".kibana-devnull", "{{.Values.elk_elasticsearch_master_project_id}}-*"]

    # admin user
    - name: Admin
      auth_key: {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}}

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
        groups: [{{.Values.ldap.es_user_groups}}]

    # get the user from the x-remote-user header
    proxy_auth_configs:
    - name: ingress
      user_id_header: "X-REMOTE-USER"

    # ldap connection definition
    ldaps:
    - name: ldap1
      host: "{{ .Values.ldap.host }}"
      port: {{ .Values.ldap.port }}
      ssl_enabled: {{ .Values.ldap.ssl }}
      ssl_trust_all_certs: {{ .Values.ldap.ssl_skip_verify}}
      bind_dn: "{{.Values.ldap.bind_dn}},{{ .Values.ldap.suffix }}"
      bind_password: "{{ .Values.ldap.password }}"
      search_user_base_DN: "OU=Identities,{{ .Values.ldap.suffix }}"
      user_id_attribute: "sAMAccountName"
      search_groups_base_DN: "{{ .Values.ldap.group_search_base_dns }},{{ .Values.ldap.suffix }}"
      unique_member_attribute: "member"
      connection_pool_size: 10
      connection_timeout_in_sec: 10
      request_timeout_in_sec: 10
      cache_ttl_in_sec: 300
