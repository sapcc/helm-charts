client:
  hosts:
    - {{.Values.elk_elasticsearch_endpoint_host_internal}}
  port: {{.Values.elk_elasticsearch_port_internal}}
  url_prefix:
  use_ssl: False
  certificate:
  client_cert:
  client_key:
  aws_key:
  aws_secret_key:
  aws_region:
  ssl_no_validate: False
  http_auth: {{.Values.elk_elasticsearch_admin_user}}:{{.Values.elk_elasticsearch_admin_password}}
  timeout: 60
  master_only: False

logging:
  loglevel: INFO
  logfile:
  logformat: default
  blacklist: ['elasticsearch', 'urllib3']
