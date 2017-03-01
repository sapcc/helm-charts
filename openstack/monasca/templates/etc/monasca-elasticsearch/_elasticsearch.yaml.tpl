cluster.name: {{.Values.monasca_elasticsearch_cluster_name}}

cloud:
  kubernetes:
    service: es-master
    namespace: {{.Values.monasca_namespace}} 

node:
  master: ${NODE_MASTER}
  data: ${NODE_DATA}

path:
  data: /data/data
  logs: /data/log

network.host: 0.0.0.0
http.enabled: ${HTTP_ENABLE}
http.max_content_length: 500mb

discovery.zen.hosts_provider: kubernetes

discovery.zen.minimum_master_nodes: 2

readonlyrest:
    enable: true
    response_if_req_forbidden: <h1>Forbidden</h1>    
    access_control_rules:

    - name: data
      type: allow
      actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
      indices: ["logstash-*",]
      auth_key: {{.Values.monasca_elasticsearch_data_user}}:{{.Values.monasca_elasticsearch_data_password}}

    - name: audit
      type: allow
      actions: ["indices:admin/types/exists","indices:data/read/*","indices:data/write/*","indices:admin/template/*","indices:admin/create","cluster:monitor/*"]
      indices: ["audit-*",]
      auth_key: {{.Values.monasca_elasticsearch_audit_user}}:{{.Values.monasca_elasticsearch_audit_password}}
 
    - name: Monsoon (read only, but can create dashboards)
      type: allow
      kibana_access: ro
      indices: [".kibana", ".kibana-devnull", "logstash-*"]

    - name: Admin
      type: allow
      auth_key: {{.Values.monasca_elasticsearch_admin_user}}:{{.Values.monasca_elasticsearch_admin_password}}
