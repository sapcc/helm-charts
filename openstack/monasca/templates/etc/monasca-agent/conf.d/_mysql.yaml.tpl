{{- define "monasca_agent_conf_d_mysql_yaml_tpl" -}}
init_config: 

instances:
 - name: mysql
   dimensions:
     service: monitoring
     component: mysql
   server: {{.Values.monasca_mysql_endpoint_host_internal}}
   user: monapi
   pass: {{.Values.monasca_mysql_monapi_password}}
   port: {{.Values.monasca_mysql_port_internal}}
{{ end }}
