{{- define "monasca_notification_notification_config_yml_tpl" -}}
kafka:
    url: kafka:{{.Values.monasca_kafka_port_internal}}
    group: notification
    consumer_id: KAFKA_CONSUMER_ID
    alarm_topic: alarm-state-transitions
    notification_topic: alarm-notifications
    notification_retry_topic: retry-notifications
    max_offset_lag: 600  # In seconds, undefined for none
    periodic:
        60: {{.Values.monasca_topics_notifications_periodic_60}}

mysql:
    host: {{.Values.monasca_mysql_endpoint_host_internal}}
    user: notification
    passwd: {{.Values.monasca_mysql_notification_password}}
    db: mon
# A dictionary set according to the params defined in, http://dev.mysql.com/doc/refman/5.0/en/mysql-ssl-set.html
#    ssl: {'ca': '/path/to/ca'}

notification_types:
    plugins:
        #-  monasca_notification.plugins.hipchat_notifier:HipChatNotifier
        - monasca_notification.plugins.slack_notifier:SlackNotifier

    email:
        server: mail.sap.corp
        port: 25
        user:
        password:
        timeout: 60
        from_addr: noreply+monasca-{{.Values.cluster_region}}@sap.corp

    webhook:
        timeout: 5

    slack:
        timeout: 5
        ca_certs: "/etc/ssl/certs/ca-certificates.crt"
        insecure: False
#        proxy: {{.Values.cluster_proxy_https}}

processors:
    alarm:
        number: 2
        ttl: 14400  # In seconds, undefined for none. Alarms older than this are not processed
    notification:
        number: 4

retry:
    interval: 30
    max_attempts: 5

queues:
    alarms_size: 256
    finished_size: 256
    notifications_size: 256
    sent_notifications_size: 50  # limiting this size reduces potential # of re-sent notifications after a failure

zookeeper:
    url: zk:{{.Values.monasca_zookeeper_port_internal}}
    notification_path: /notification/alarms
    notification_retry_path: /notification/retry
    periodic_path:
        60: /notification/60_seconds


logging: # Used in logging.dictConfig
    version: 1
    disable_existing_loggers: False
    formatters:
        default:
            format: "%(asctime)s %(levelname)s %(name)s %(message)s"
    handlers:
        console:
            class: logging.StreamHandler
            formatter: default
    loggers:
        kazoo:
            level: WARN
        kafka:
            level: WARN
        statsd:
            level: INFO
    root:
        handlers:
            - console
        level: {{.Values.monasca_notification_loglevel}} 
{{ end }}
