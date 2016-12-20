{{- define "monasca_elasticsearch_logging_yaml_tpl" -}}
# you can override this using by setting a system property, for example -Des.logger.level=DEBUG
es.logger.level: {{.Values.monasca_elasticsearch_loglevel}}
rootLogger: ${es.logger.level}, console
logger:
  # log action execution errors for easier debugging
  action: WARN
  # reduce the logging for aws, too much is logged under the default INFO
  com.amazonaws: WARN

  # gateway
  #gateway: DEBUG
  #index.gateway: DEBUG

  # peer shard recovery
  #indices.recovery: DEBUG

  # discovery
  #discovery: TRACE

appender:
  console:
    type: console
    layout:
      type: consolePattern
      conversionPattern: "[%d{ISO8601}][%-5p][%-25c] %m%n"
{{ end }}
