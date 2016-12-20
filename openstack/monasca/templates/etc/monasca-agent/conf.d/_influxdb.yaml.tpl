{{- define "monasca_agent_conf_d_influxdb_yaml_tpl" -}}
init_config:

instances:
 - name: InfluxDB
   dimensions:
     service: monitoring
     component: influxdb
   url: http://{{.Values.monasca_influxdb_endpoint_host_internal}}:{{.Values.monasca_influxdb_port_internal}}
   timeout: 50
   collect_response_time: true
   username: {{.Values.monasca_influxdb_monitoring_username}}
   password: {{.Values.monasca_influxdb_monitoring_password}}
   whitelist:
     engine:
       - points_write
       - points_write_dedupe
     httpd:
       - points_write_ok
       - query_req
       - write_req
     shard:
       - series_create
       - fields_create
       - write_req
       - points_write_ok
{{ end }}
