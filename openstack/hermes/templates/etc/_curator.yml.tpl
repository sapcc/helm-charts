client:
  hosts:
    - {{required ".Values.hermes_elasticsearch_host is missing" .Values.hermes_elasticsearch_host}}
  port: {{required ".Values.hermes_elasticsearch_port" .Values.hermes_elasticsearch_port}}
  url_prefix:
  use_ssl: False
  certificate:
  client_cert:
  client_key:
  aws_key:
  aws_secret_key:
  aws_region:
  ssl_no_validate: False
  timeout: 60
  master_only: False

logging:
  loglevel: INFO
  logfile:
  logformat: default
  blacklist: ['elasticsearch', 'urllib3']
