cluster.name: {{.Values.elk_elasticsearch_cluster_name}}

cloud:
  kubernetes:
    service: es-master
    namespace: {{.Values.elk_namespace}}

node:
  master: ${NODE_MASTER}
  data: ${NODE_DATA}

path:
  data: /data/data
  logs: /data/log

network.host: 0.0.0.0
transport.host: 0.0.0.0
http.enabled: ${HTTP_ENABLE}
http.max_content_length: 500mb

discovery.zen.hosts_provider: kubernetes

discovery.zen.minimum_master_nodes: 2

readonlyrest:
    enable: true
    response_if_req_forbidden: <h1>Forbidden</h1>
    
    proxy_auth_configs:

    - name: "ingress"
      user_id_header: "X-Remote-User"

    access_control_rules:

    - name: data
      actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
      indices: ["logstash-*"]
      auth_key: {{.Values.elk_elasticsearch_data_user}}:{{.Values.elk_elasticsearch_data_password}}

    - name: jump
      actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
      indices: ["jump-*"]
      auth_key: {{.Values.elk_elasticsearch_jump_user}}:{{.Values.elk_elasticsearch_jump_password}}

    - name: Monsoon (read only, but can create dashboards)
      kibana_access: ro
      auth_key: {{.Values.elk_elasticsearch_monsoon_user}}:{{.Values.elk_elasticsearch_monsoon_password}}
      indices: [".kibana", ".kibana-devnull", "{{.Values.elk_elasticsearch_master_project_id}}-*"]

    - name: Admin
      auth_key: {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}}

#    - name: Everyone
#      type: allow

    - name: LDAP auth
      type: allow
      ldap_auth:
        name: "ldap1"
        groups: [{{.Values.ldap.es_user_groups}}]

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
