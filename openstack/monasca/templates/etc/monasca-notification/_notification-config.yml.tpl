kafka:
    url: kafka:{{.Values.monasca_kafka_port_internal}}
    group: notification
    consumer_id: KAFKA_CONSUMER_ID
    client_id: monasca-notification
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
        template:
            subject: "{{`{{ {'ALARM': '*Alarm triggered*', 'OK': 'Alarm cleared', 'UNDETERMINED':'Missing alarm data'}[state] }} for {{alarm_name}}`}}"
            text: |
                <table style="height: 108px;" width="805" cellspacing="10pt">
                <tbody>
                <tr>
                <td><img src="https://upload.wikimedia.org/wikipedia/en/8/85/Big_Brother_UK_5_logo.png" alt="" width="64" height="50" /></td>
                <td><h1>Converged Cloud Monitoring Notification</h1></td>
                <td><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/5/59/SAP_2011_logo.svg/640px-SAP_2011_logo.svg.png" alt="SAP Logo" width="98" height="50" /></td>
                </tr>
                </tbody>
                </table>
                <h2>Alarm <a href="https://dashboard.{{.Values.cluster_region}}.cloud.sap/ccadmin/master/monitoring/alarms?overlay={{&#96;{{alarm_id}}&#96;}}">{{`alarm_name`}}</a>&nbsp;changed to status<span style="color: #ff0000;"> {{`status&acute;}}</span></h2>
                <p>{{`{{alarm_description}}`}}</p>
                <p>Additional Information:</p>
                <table>
                <tbody>
                <tr>
                <td style="text-align: left;"><strong>Status</strong></td>
                <td>{{`{{_state}}`}}</td>
                <td><strong>Previous State</strong></td>
                <td>{{`{{_old_state}}`}}</td>
                </tr>
                <tr>
                <td style="text-align: left;"><strong>Severity</strong></td>
                <td>{{`{{_severity}}`}}</td>
                <td><strong>Timestamp</strong></td>
                <td>{{`{{_timestamp}}`}}</td>
                </tr>
                </tbody>
                </table>
        mime_type: text/html
    webhook:
        timeout: 5

    slack:
        timeout: 5
        ca_certs: "/etc/ssl/certs/ca-certificates.crt"
        insecure: False
#        proxy: {{.Values.cluster_proxy_https}}
        template:
            text: |
                {
                    "username": "Monasca ({{.Values.cluster_region}})",
                    "icon_url": "https://upload.wikimedia.org/wikipedia/en/8/85/Big_Brother_UK_5_logo.png",
                    "mrkdwn": true,
                    "attachments": [
                        {
                            "fallback": "{{`{{alarm_description}}`}}",
                            "color": "{{`{{ {'ALARM': '#d60000', 'OK': '#36a64f', 'UNDETERMINED': '#fff000'}[state] }}`}}",
                            "title": "{{`{{ {'ALARM': '*Alarm triggered*', 'OK': 'Alarm cleared', 'UNDETERMINED':'Missing alarm data'}[state] }}`}} for {{`{{alarm_name}}`}} in {{.Values.cluster_region}}",
                            "title_link": "https://dashboard.{{.Values.cluster_region}}.cloud.sap/ccadmin/master/monitoring/alarms?overlay={{`{{alarm_id}}`}}",
                            "text": "{% if state == 'ALARM' %}:bomb:{{`{{alarm_description}}`}}\n{{`{{message}}`}}{% elif state == 'OK' %}:white_check_mark: Resolved: {{`{{alarm_description}}`}}{% else %}:grey_question:{{`{{alarm_description}}`}}{% endif %}",
                            {% if state == 'ALARM' %}
                            "fields": [
                                {
                                    "title": "Region",
                                    "value": "{{.Values.cluster_region}}",
                                    "short": true
                                },
                                {
                                    "title": "Severity",
                                    "value": "{{`{{severity}}`}}",
                                    "short": true
                                }
                            ],
                            {% endif %}
                            "mrkdwn_in": ["text", "title", "fallback"]
                        }
                    ]
                }
            mime_type: application/json

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
