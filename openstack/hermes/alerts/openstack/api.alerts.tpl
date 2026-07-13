# vim: set ft=yaml:

groups:
- name: openstack-hermes.alerts
  rules:
  - alert: OpenstackHermesHttpErrors
    expr: sum(increase(promhttp_metric_handler_requests_total{kubernetes_namespace="hermes",code=~"5.*"}[1h])) by (kubernetes_name) > 0
    for: 5m
    labels:
      context: api
      dashboard: hermes-api
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-api"
      service: hermes
      severity: info
      support_group: observability
      tier: os
    annotations:
      description: "{{`{{ $labels.kubernetes_name }}`}} is producing HTTP responses with 5xx status codes."
      summary: "Server errors on {{`{{ $labels.kubernetes_name }}`}}"

  - alert: OpenstackHermesKeystoneAvail
    expr: sum(rate(hermes_logon_errors_count[10m])) > 0
    for: 15m
    labels:
      context: availability
      dashboard: hermes-api
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-api"
      service: hermes
      severity: warning
      tier: os
      support_group: observability
    annotations:
      description: Hermes API is affected by errors when accessing Keystone
      summary: Hermes availability affected by Keystone issues

  - alert: OpenstackHermesElasticAvail
    expr: sum(rate(hermes_storage_errors_count[10m])) > 0
    for: 15m
    labels:
      context: availability
      dashboard: hermes-api
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-api"
      service: hermes
      severity: warning
      tier: os
      support_group: observability
    annotations:
      description: Hermes API is affected by storage errors while accessing Elasticsearch
      summary: Hermes availability affected by storage errors while accessing Elasticsearch

  - alert: OpenstackHermesRabbitMQUnack
    expr: sum(rabbitmq_queue_messages_unacked{kubernetes_name=~".*rabbitmq-notifications"}) by (kubernetes_name) > 10000
    labels:
      context: rabbitmq
      severity: warning
      tier: os
      support_group: observability
      service: hermes
      dashboard: rabbitmq
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/rabbitmq"
      meta: "{{`{{ $labels.service }}`}} {{`{{ $labels.check }}`}} has over 10000 unacknowledged messages in {{`{{ $labels.kubernetes_name }}`}}. Logstash has disconnected from the RabbitMQ."
      playbook: "docs/devops/alert/hermes/#{{`{{ $labels.check }}`}}"
    annotations:
      description: "{{`{{ $labels.service }}`}} {{`{{ $labels.check }}`}} has over 10000 unacknowledged messages in {{`{{ $labels.kubernetes_name }}`}}. Logstash has disconnected from the RabbitMQ."
      summary: "RabbitMQ unacknowledged messages count"

  - alert: OpenstackHermesRabbitMQReady
    expr: sum(rabbitmq_queue_messages_ready{kubernetes_name=~".*rabbitmq-notifications"}) by (kubernetes_name) > 10000
    # for: requires the backlog to persist before firing, so a single scrape spike does not
    # trigger the alert and cause it to flap WARNING<->RESOLVED.
    for: 15m
    labels:
      context: rabbitmq
      severity: warning
      tier: os
      support_group: observability
      service: hermes
      dashboard: rabbitmq
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/rabbitmq"
      meta: "{{`{{ $labels.service }}`}} {{`{{ $labels.check }}`}} has over 10000 ready messages in {{`{{ $labels.kubernetes_name }}`}}. Logstash has disconnected from the RabbitMQ."
      playbook: "docs/devops/alert/rabbitmq/#ready"
    annotations:
      description: "{{`{{ $labels.service }}`}} {{`{{ $labels.check }}`}} has over 10000 ready messages in {{`{{ $labels.kubernetes_name }}`}}. Logstash has disconnected from the RabbitMQ."
      summary: "RabbitMQ ready messages count"

  # Critical escalation for a large, sustained backlog. A per-broker backlog this deep means a
  # queue is not being drained and the data volume is at real risk of filling. This tier pages;
  # the warning tier above only notifies.
  - alert: OpenstackHermesRabbitMQReadyCritical
    expr: sum(rabbitmq_queue_messages_ready{kubernetes_name=~".*rabbitmq-notifications"}) by (kubernetes_name) > 1000000
    for: 15m
    labels:
      context: rabbitmq
      severity: critical
      tier: os
      support_group: observability
      service: hermes
      dashboard: rabbitmq
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/rabbitmq"
      meta: "{{`{{ $labels.service }}`}} {{`{{ $labels.check }}`}} has over 1,000,000 ready messages in {{`{{ $labels.kubernetes_name }}`}}. A queue is not draining and the RabbitMQ volume is at risk of filling."
      playbook: "docs/devops/alert/rabbitmq/#ready"
    annotations:
      description: "{{`{{ $labels.service }}`}} {{`{{ $labels.check }}`}} has over 1,000,000 ready messages in {{`{{ $labels.kubernetes_name }}`}}. A queue is not draining and the RabbitMQ volume is at risk of filling."
      summary: "RabbitMQ backlog critically large"

  # The three rabbitmq-notifications pods are independent singletons behind a Kubernetes Service.
  # A consumer using one Service-backed connection can end up consuming only some of them, leaving
  # a broker with a growing backlog and ZERO consumers. That stranded queue is what eventually
  # fills the disk. This is a leading indicator, so it warns; a persistent strand escalates below.
  - alert: OpenstackHermesRabbitMQQueueStranded
    expr: |
      (rabbitmq_queue_messages_ready{kubernetes_name=~".*rabbitmq-notifications"} > 0)
      and on(pod)
      (rabbitmq_queue_consumers{kubernetes_name=~".*rabbitmq-notifications"} == 0)
    for: 10m
    labels:
      context: rabbitmq
      severity: warning
      tier: os
      support_group: observability
      service: hermes
      dashboard: rabbitmq
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/rabbitmq"
      meta: "Broker {{`{{ $labels.pod }}`}} has ready messages but ZERO consumers -- it is stranded and will fill the disk if not drained."
      playbook: "docs/devops/alert/rabbitmq/#ready"
    annotations:
      description: "RabbitMQ broker {{`{{ $labels.pod }}`}} has ready messages but no consumers. A RabbitMQ singleton is not being drained by log-router; restart/rebalance consumers before the volume fills."
      summary: "RabbitMQ broker stranded (ready messages, zero consumers)"

  # Persistent-strand escalation. A transient strand clears on its own; one that persists for an
  # hour will not, and the volume will fill. This pages, while the warning above only notifies.
  - alert: OpenstackHermesRabbitMQQueueStrandedPersistent
    expr: |
      (rabbitmq_queue_messages_ready{kubernetes_name=~".*rabbitmq-notifications"} > 0)
      and on(pod)
      (rabbitmq_queue_consumers{kubernetes_name=~".*rabbitmq-notifications"} == 0)
    for: 1h
    labels:
      context: rabbitmq
      severity: critical
      tier: os
      support_group: observability
      service: hermes
      dashboard: rabbitmq
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/rabbitmq"
      meta: "Broker {{`{{ $labels.pod }}`}} has been stranded (ready messages, ZERO consumers) for over an hour and will fill the disk."
      playbook: "docs/devops/alert/rabbitmq/#ready"
    annotations:
      description: "RabbitMQ broker {{`{{ $labels.pod }}`}} has had ready messages with no consumers for over an hour. It is not self-recovering; restart/rebalance consumers now before the volume fills."
      summary: "RabbitMQ broker stranded for over an hour"

  # True "down" trigger. When RabbitMQ raises the free-disk watermark it STOPS accepting publishes
  # on that broker, which is the actual outage rather than a symptom. This is Hermes-owned and
  # pages immediately, rather than relying on a generic platform-level volume alert.
  - alert: OpenstackHermesRabbitMQDiskWatermark
    expr: max(rabbitmq_alarms_free_disk_space_watermark{kubernetes_name=~".*rabbitmq-notifications"}) by (pod) == 1
    for: 2m
    labels:
      context: rabbitmq
      severity: critical
      tier: os
      support_group: observability
      service: hermes
      dashboard: rabbitmq
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/rabbitmq"
      meta: "{{`{{ $labels.pod }}`}} has hit the RabbitMQ free-disk watermark and is now BLOCKING publishers. Audit ingestion is stopping on this broker."
      playbook: "docs/devops/alert/rabbitmq/#ready"
    annotations:
      description: "{{`{{ $labels.pod }}`}} has raised the RabbitMQ free-disk-space watermark alarm and is blocking publishers. This is an active ingestion outage on this broker; free disk or drain the queue immediately."
      summary: "RabbitMQ blocking publishers (free-disk watermark)"

  - alert: OpenstackHermesLogstashPlugins
    expr: sum(increase(logstash_node_plugin_events_out_total[30m])) <= 0
    labels:
      context: logstash
      severity: warning
      tier: os
      support_group: observability
      service: hermes
      dashboard: hermes-logstash-metrics
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-logstash-metrics"
      meta: "Hermes logstash plugin {{`{{ $labels.plugin }}`}} has stopped transmitting data"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Hermes logstash plugin {{`{{ $labels.plugin }}`}} has stopped transmitting data"
      summary: "Hermes logstash plugin {{`{{ $labels.plugin }}`}} has stopped transmitting data"

  - alert: OpenstackHermesLogstashPluginsJDBCStaticFailure
    expr: sum(rate(logstash_node_plugin_failures_total{namespace=~"hermes",plugin="jdbc_static"}[10m])) > 0
    labels:
      context: logstash
      severity: warning
      tier: os
      support_group: observability
      service: hermes
      dashboard: hermes-logstash-metrics
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-logstash-metrics"
      meta: "Hermes logstash plugin {{`{{ $labels.plugin }}`}} has failed enriching data with Metis"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Hermes logstash plugin {{`{{ $labels.plugin }}`}} has failed enriching data with Metis"
      summary: "Hermes logstash plugin {{`{{ $labels.plugin }}`}} has failed enriching data with Metis"
      
  - alert: OpenstackHermesUp
    expr: up{component="hermes",namespace="hermes"} < 1
    for: 15m
    labels:
      component: '{{`{{ $labels.component }}`}}'
      context: availability
      dashboard: hermes-api
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-api"
      service: hermes
      severity: critical
      tier: os
      support_group: observability
      meta: "CCloud Hermes API is down"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: Hermes monitoring endpoint is down => Hermes is down
      summary: Hermes API is not available, check pod logs

  - alert: OpenstackHermesLogRouterRabbitMQDisconnected
    expr: sum(log_router_rabbitmq_connected) == 0
    for: 2m
    labels:
      context: log-router
      dashboard: hermes-log-router
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-log-router"
      service: hermes
      severity: critical
      support_group: observability
      tier: os
      meta: "Log Router has lost its RabbitMQ connection — no audit events are being consumed"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "All log-router pods have lost their RabbitMQ connection. No audit events are being consumed from the queue. The queue depth will grow until the connection is restored."
      summary: "Log Router disconnected from RabbitMQ"

  - alert: OpenstackHermesLogRouterDLQFallback
    expr: sum(rate(log_router_flush_dlq_fallbacks_total[5m])) > 0
    for: 5m
    labels:
      context: log-router
      dashboard: hermes-log-router
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-log-router"
      service: hermes
      severity: critical
      support_group: observability
      tier: os
      meta: "Log Router is routing audit data to the DLQ after exhausting flush retries — data is not landing in the customer S3 bucket"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Log Router flush retries have been exhausted and partitions are being routed to the DLQ. Audit events are not being written to the primary S3/Ceph bucket. Check S3 connectivity, bucket Object Lock configuration, and credentials."
      summary: "Log Router falling back to DLQ — data not reaching S3"

  - alert: OpenstackHermesLogRouterAdminWriteErrors
    expr: sum(rate(log_router_admin_write_errors_total[5m])) > 0
    for: 5m
    labels:
      context: log-router
      dashboard: hermes-log-router
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-log-router"
      service: hermes
      severity: critical
      support_group: observability
      tier: os
      meta: "Log Router admin-tier write errors — compliance audit copies may be missing from the admin bucket"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Log Router is failing to write to the admin-tier storage. The admin tier provides unconditional compliance copies of all audit events. Sustained errors mean audit records are missing from the admin bucket."
      summary: "Log Router admin-tier write errors — compliance data at risk"
