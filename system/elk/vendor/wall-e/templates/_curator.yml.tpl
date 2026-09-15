client:
  hosts:
    - {{.Values.endpoint_host_internal}}
  port: {{.Values.http_port}}
  url_prefix:
  use_ssl: False
  certificate:
  client_cert:
  client_key:
  aws_key:
  aws_secret_key:
  aws_region:
  ssl_no_validate: False
  username: {{.Values.global.elk_elasticsearch_admin_user}}
  password: {{.Values.global.elk_elasticsearch_admin_password}}
  timeout: 60
  master_only: False

logging:
  loglevel: INFO
  logfile:
  logformat: default
  blacklist: ['elasticsearch', 'urllib3']
