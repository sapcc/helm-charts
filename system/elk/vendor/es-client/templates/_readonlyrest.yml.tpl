# rbac for elasticsearch
readonlyrest:
    enable: true
    response_if_req_forbidden: <h1>Forbidden</h1>
    audit:
      collector: {{.Values.audit}}

    access_control_rules:

      # access for logstash to write to the logstash indexes
      - name: data
        actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
        indices: ["logstash-*", "netflow-*", "systemd-*", "syslog-*", ".kibana*", "kubernikus-*", "scaleout-*", "virtual-*", "bigiplogs-*", "alerts-*", "deployments-*","nsxt-*"]
        auth_key: {{.Values.global.elk_elasticsearch_data_user}}:{{.Values.global.elk_elasticsearch_data_password}}
        verbosity: error

      # access for logstash to write to the audit indexes
      - name: audit
        actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
        indices: ["audit-*"]
        auth_key: {{.Values.global.elk_elasticsearch_audit_user}}:{{.Values.global.elk_elasticsearch_audit_password}}
        verbosity: error

{{- if .Values.qalogs.enabled }}
      - name: qade2
        actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
        indices: ["qade2-logstash-*"]
        auth_key: {{.Values.global.elk_elasticsearch_qade2_user}}:{{.Values.global.elk_elasticsearch_qade2_password}}
        verbosity: error

      - name: qade3
        actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
        indices: ["qade3-logstash-*"]
        auth_key: {{.Values.global.elk_elasticsearch_qade3_user}}:{{.Values.global.elk_elasticsearch_qade3_password}}
        verbosity: error

      - name: qade5
        actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
        indices: ["qade5-logstash-*"]
        auth_key: {{.Values.global.elk_elasticsearch_qade5_user}}:{{.Values.global.elk_elasticsearch_qade5_password}}
        verbosity: error

{{- end }}
      # access to write to the jump server log indexes
      - name: jump
        actions: ["*"]
        indices: ["jump-*"]
        auth_key: {{.Values.global.elk_elasticsearch_jump_user}}:{{.Values.global.elk_elasticsearch_jump_password}}
        verbosity: error

      # access for jaeger to write traces indexes
      - name: jaeger
        actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
        indices: ["jaeger-*"]
        auth_key: {{.Values.global.elk_elasticsearch_jaeger_user}}:{{.Values.global.elk_elasticsearch_jaeger_password}}
        verbosity: info

      # access for winbeat
      - name: winbeat
        actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
        indices: ["winbeat-*", "winlogbeat-*"]
        auth_key: {{.Values.global.elk_elasticsearch_winbeat_user}}:{{.Values.global.elk_elasticsearch_winbeat_password}}
        verbosity: error

      - name: Monsoon (read only, but can create dashboards)
        kibana_access: ro
        auth_key: {{.Values.global.elk_elasticsearch_monsoon_user}}:{{.Values.global.elk_elasticsearch_monsoon_password}}
        indices: [".kibana*", ".kibana-devnull", {{.Values.global.indexes}}]
        verbosity: error

      - name: promuser
        actions: ["indices:data/read/*", "cluster:monitor/state", "indices:admin/get", "indices:admin/mappings/fields/get", "indices:admin/mappings/get", "indices:admin/aliases/get", "indices:admin/template/get", "cluster:monitor/prometheus/metrics", "cluster:monitor/health", "cluster:monitor/nodes/stats", "cluster:monitor/state", "indices:monitor/stats"]
        indices: ["logstash-*", "netflow", "systemd-*", "syslog-*", "jump-*", "kubernikus-*", "scaleout-*", "virtual-*"]
        auth_key: {{.Values.global.prom_user}}:{{.Values.global.prom_password}}
        verbosity: error

      # admin user
      - name: Admin
        auth_key: {{.Values.global.elk_elasticsearch_admin_user}}:{{.Values.global.elk_elasticsearch_admin_password}}
        verbosity: error

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
      bind_password: "{{ .Values.global.ldap.password }}"
      search_user_base_DN: "OU=Identities,{{ .Values.global.ldap.suffix }}"
      user_id_attribute: "sAMAccountName"
      search_groups_base_DN: "{{ .Values.global.ldap.group_search_base_dns }},{{ .Values.global.ldap.suffix }}"
      unique_member_attribute: "member"
      connection_pool_size: 10
      connection_timeout_in_sec: 10
      request_timeout_in_sec: 10
      cache_ttl_in_sec: 300
      ignore_ldap_connectivity_problems: true
