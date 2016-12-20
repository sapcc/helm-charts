{{- define "monasca_agent_conf_d_elastic_yaml_tpl" -}}
init_config:

instances:
  - name: elastic
    url: http://127.0.0.1:{{.Values.monasca_elasticsearch_port_internal}}
    username: {{.Values.monasca_elasticsearch_admin_user}}
    password: {{.Values.monasca_elasticsearch_admin_password}}
    dimensions:
      service: monitoring
      component: elasticsearch
{{ end }}
