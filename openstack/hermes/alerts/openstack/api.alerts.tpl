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
    expr: sum(rabbitmq_queue_messages_unacked{kubernetes_name=~".*rabbitmq-(notifications|dataplane)"}) by (kubernetes_name) > 10000
    for: 15m
    labels:
      context: rabbitmq
      severity: warning
      tier: os
      support_group: observability
      service: hermes
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/rabbitmq"
      meta: "{{`{{ $labels.service }}`}} {{`{{ $labels.check }}`}} has over 10000 unacknowledged messages in {{`{{ $labels.kubernetes_name }}`}}. Logstash has disconnected from the RabbitMQ."
      playbook: "docs/devops/alert/hermes/#{{`{{ $labels.check }}`}}"
    annotations:
      description: "{{`{{ $labels.service }}`}} {{`{{ $labels.check }}`}} has over 10000 unacknowledged messages in {{`{{ $labels.kubernetes_name }}`}}. Logstash has disconnected from the RabbitMQ."
      summary: "RabbitMQ unacknowledged messages count"

  - alert: OpenstackHermesRabbitMQReady
    expr: sum(rabbitmq_queue_messages_ready{kubernetes_name=~".*rabbitmq-(notifications|dataplane)"}) by (kubernetes_name) > 10000
    # for: requires the backlog to persist before firing, so a single scrape spike does not
    # trigger the alert and cause it to flap WARNING<->RESOLVED.
    for: 15m
    labels:
      context: rabbitmq
      severity: warning
      tier: os
      support_group: observability
      service: hermes
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
    expr: sum(rabbitmq_queue_messages_ready{kubernetes_name=~".*rabbitmq-(notifications|dataplane)"}) by (kubernetes_name) > 1000000
    for: 15m
    labels:
      context: rabbitmq
      severity: critical
      tier: os
      support_group: observability
      service: hermes
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
      (rabbitmq_queue_messages_ready{kubernetes_name=~".*rabbitmq-(notifications|dataplane)"} > 0)
      and on(pod)
      (rabbitmq_queue_consumers{kubernetes_name=~".*rabbitmq-(notifications|dataplane)"} == 0)
    for: 10m
    labels:
      context: rabbitmq
      severity: warning
      tier: os
      support_group: observability
      service: hermes
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
      (rabbitmq_queue_messages_ready{kubernetes_name=~".*rabbitmq-(notifications|dataplane)"} > 0)
      and on(pod)
      (rabbitmq_queue_consumers{kubernetes_name=~".*rabbitmq-(notifications|dataplane)"} == 0)
    for: 1h
    labels:
      context: rabbitmq
      severity: critical
      tier: os
      support_group: observability
      service: hermes
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
    expr: max(rabbitmq_alarms_free_disk_space_watermark{kubernetes_name=~".*rabbitmq-(notifications|dataplane)"}) by (pod) == 1
    for: 2m
    labels:
      context: rabbitmq
      severity: critical
      tier: os
      support_group: observability
      service: hermes
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/rabbitmq"
      meta: "{{`{{ $labels.pod }}`}} has hit the RabbitMQ free-disk watermark and is now BLOCKING publishers. Audit ingestion is stopping on this broker."
      playbook: "docs/devops/alert/rabbitmq/#ready"
    annotations:
      description: "{{`{{ $labels.pod }}`}} has raised the RabbitMQ free-disk-space watermark alarm and is blocking publishers. This is an active ingestion outage on this broker; free disk or drain the queue immediately."
      summary: "RabbitMQ blocking publishers (free-disk watermark)"

  - alert: OpenstackHermesLogstashPlugins
    expr: sum(increase(logstash_stats_pipeline_plugin_events_out[30m])) <= 0
    for: 15m
    labels:
      context: logstash
      severity: warning
      tier: os
      support_group: observability
      service: hermes
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-logstash-metrics"
      meta: "Hermes logstash plugin {{`{{ $labels.plugin }}`}} has stopped transmitting data"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Hermes logstash plugin {{`{{ $labels.plugin }}`}} has stopped transmitting data"
      summary: "Hermes logstash plugin {{`{{ $labels.plugin }}`}} has stopped transmitting data"

  - alert: OpenstackHermesLogstashKafkaFailure
    expr: sum(rate(logstash_stats_pipeline_plugin_bulk_requests_errors{namespace=~"hermes",plugin="kafka"}[10m])) + sum(rate(logstash_stats_pipeline_plugin_documents_non_retryable_failures{namespace=~"hermes",plugin="kafka"}[10m])) > 0
    for: 5m
    labels:
      context: logstash
      severity: warning
      tier: os
      support_group: observability
      service: hermes
      no_alert_on_absence: "true" # kafka output is disabled by default; metric is absent when logstash.kafka.enabled=false
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-logstash-metrics"
      meta: "Hermes logstash Kafka output plugin is failing to deliver audit events"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Hermes logstash Kafka output plugin is failing to deliver audit events to the SIEM broker"
      summary: "Hermes logstash Kafka output plugin is failing"

  - alert: OpenstackHermesLogstashPluginsJDBCStaticFailure
    expr: sum(rate(logstash_stats_pipeline_plugin_bulk_requests_errors{namespace=~"hermes",plugin="jdbc_static"}[10m])) + sum(rate(logstash_stats_pipeline_plugin_documents_non_retryable_failures{namespace=~"hermes",plugin="jdbc_static"}[10m])) > 0
    for: 5m
    labels:
      context: logstash
      severity: warning
      tier: os
      support_group: observability
      service: hermes
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

{{- if .Values.logRouter.enabled }}
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
      severity: warning
      support_group: observability
      tier: os
      meta: "Log Router is routing audit data to the DLQ after exhausting flush retries — data is not landing in the customer S3 bucket"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Log Router flush retries have been exhausted and partitions are being routed to the DLQ. Audit events are not being written to the primary S3/Ceph bucket. Check S3 connectivity, bucket Object Lock configuration, and credentials."
      summary: "Log Router falling back to DLQ — data not reaching S3"

  - alert: OpenstackHermesLogRouterAllWritesDenied
    # writer_not_authorized: newer log-router keeps those events and counts log_router_writer_not_authorized_total; older ones dropped them.
    expr: (sum(increase(log_router_events_dropped_total{reason=~"access_denied|writer_not_authorized"}[15m])) > 0 or sum(increase(log_router_writer_not_authorized_total[15m])) > 0) and sum(increase(log_router_events_flushed_total[15m])) == 0
    for: 5m
    labels:
      context: log-router
      dashboard: hermes-log-router
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-log-router"
      service: hermes
      severity: warning
      support_group: observability
      tier: os
      no_alert_on_absence: "true" # writer_not_authorized_total only exists after a refusal; OpenstackHermesLogRouterFlushFailing covers events_flushed_total
      meta: "Log Router: every write is denied, nothing has been flushed for 15m"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Log Router is denied on every write (access_denied drops, or writer_not_authorized refusals whose events are held back) and has flushed nothing for 15m. One customer revoking access does not do this. It means access was denied on every container, for example all container ACLs were wiped (an old image rolled back after the ACL migration), or, with project-scoped writes, the writer user lost objectstore_admin in every project. A lost role on the main scope (cloud_objectstore_admin) does not show up here, see OpenstackHermesLogRouterFlushFailing."
      summary: "Log Router writes denied for all tenants"

  - alert: OpenstackHermesLogRouterWriterNotAuthorized
    # Newer log-router keeps the events and counts every refused login (once per 5m per replica);
    # older ones dropped them (1h: drops come in bursts from minute 15 of the hour on).
    expr: sum by (tenant) (increase(log_router_writer_not_authorized_total[15m])) > 0 or sum by (tenant) (increase(log_router_events_dropped_total{reason="writer_not_authorized"}[1h])) > 0
    labels:
      context: log-router
      dashboard: hermes-log-router
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-log-router"
      service: hermes
      severity: warning
      support_group: observability
      tier: os
      no_alert_on_absence: "true" # writer_not_authorized_total only exists after a refusal
      meta: "Log Router cannot write audit events of project {{`{{ $labels.tenant }}`}}: the writer user has no objectstore_admin there"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "With project-scoped writes on, Keystone refuses the writer user (hermes@Default) a token for project {{`{{ $labels.tenant }}`}}, so its audit events are held back and retried (older log-router versions drop them; held events fill the buffer memory and then delay every tenant). Usually an iaas- project that was enabled before hermes.dataplane_assign_writer_role was on and was never re-enabled. Fix: a project admin re-enables dataplane through hermez with the current config (including target_bucket), or a cloud admin runs openstack role add --user hermes --user-domain Default --project {{`{{ $labels.tenant }}`}} objectstore_admin."
      summary: "Log Router writer has no role in project {{`{{ $labels.tenant }}`}}"

  - alert: OpenstackHermesLogRouterFlushFailing
    expr: sum(increase(log_router_flush_errors_total[15m])) > 0 and sum(increase(log_router_events_flushed_total[15m])) == 0
    for: 5m
    labels:
      context: log-router
      dashboard: hermes-log-router
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-log-router"
      service: hermes
      severity: warning
      support_group: observability
      tier: os
      meta: "Log Router cannot write to object storage, events are kept in the WAL"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Log Router has had flush errors and flushed nothing for 15m, so it cannot write anywhere. Likely causes are a lost storage role (RGW answers 401), RGW or Keystone being down, or bad credentials. Events are kept in the WAL and retried, nothing is dropped yet, but the WAL grows until this is fixed."
      summary: "Log Router cannot flush to object storage"

  # The hold gauges only have a series while a project is held, so their absence is normal.
  - alert: OpenstackHermesLogRouterHeldEvents
    expr: sum by (tenant) (log_router_held_events) > 0
    for: 15m
    labels:
      context: log-router
      dashboard: hermes-log-router
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-log-router"
      service: hermes
      severity: warning
      support_group: observability
      tier: os
      no_alert_on_absence: "true" # only exported while a project is held
      meta: "Log Router is holding audit events of project {{`{{ $labels.tenant }}`}} it cannot write"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Log Router has held audit events of project {{`{{ $labels.tenant }}`}} for 15m ({{`{{ $value | humanize }}`}} events now) because writing them fails on our side. Nothing is lost yet: they stay in the WAL and are delivered once the write works. Check that the writer user has objectstore_admin in the project (see OpenstackHermesLogRouterWriterNotAuthorized) and that RGW and Keystone are reachable (see OpenstackHermesLogRouterFlushFailing)."
      summary: "Log Router holding events of project {{`{{ $labels.tenant }}`}}"

  # Budgets are per pod (each replica has its own WAL); a budget of 0 means no budget.
  # Matched on pod and instance: a recreated pod has a new IP, its old series may still be in the lookback.
  - alert: OpenstackHermesLogRouterHoldBudgetHigh
    expr: max by (tenant, pod) (log_router_held_bytes / on (pod, instance) group_left () (log_router_hold_budget_bytes{scope="tenant"} > 0)) > 0.7
    for: 5m
    labels:
      context: log-router
      dashboard: hermes-log-router
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-log-router"
      service: hermes
      severity: warning
      support_group: observability
      tier: os
      no_alert_on_absence: "true" # held_bytes is only exported while a project is held
      meta: "Log Router: held events of project {{`{{ $labels.tenant }}`}} are close to the per-project hold budget"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Held events of project {{`{{ $labels.tenant }}`}} use {{`{{ $value | humanizePercentage }}`}} of the per-project hold budget on {{`{{ $labels.pod }}`}}. When the budget is full, the oldest held events of this project are dropped and lost. Fix the write for this project before that: check the writer role in the project and that storage is reachable."
      summary: "Log Router hold budget of project {{`{{ $labels.tenant }}`}} over 70%"

  - alert: OpenstackHermesLogRouterHoldBudgetHigh
    expr: sum by (pod, instance) (log_router_held_bytes) / on (pod, instance) (log_router_hold_budget_bytes{scope="total"} > 0) > 0.7
    for: 5m
    labels:
      context: log-router
      dashboard: hermes-log-router
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-log-router"
      service: hermes
      severity: warning
      support_group: observability
      tier: os
      no_alert_on_absence: "true" # held_bytes is only exported while a project is held
      meta: "Log Router: held events on {{`{{ $labels.pod }}`}} are close to the total hold budget"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Held events of all projects on {{`{{ $labels.pod }}`}} use {{`{{ $value | humanizePercentage }}`}} of the total hold budget. When it is full, the oldest held events of the project holding the most are dropped and lost. See OpenstackHermesLogRouterHeldEvents for the projects being held and fix their writes; if nothing gets written at all, see OpenstackHermesLogRouterFlushFailing."
      summary: "Log Router total hold budget on {{`{{ $labels.pod }}`}} over 70%"

  # log-router creates the tenant's hold_budget_exceeded counter at 0 when the tenant gets held,
  # so increase() sees the first drop. Drops at startup (budget enforced at the end of WAL recovery,
  # e.g. after a budget was lowered) come before the first scrape: any count of a process younger than 15m counts too.
  - alert: OpenstackHermesLogRouterHoldBudgetDrop
    expr: sum by (tenant) (log_router_events_dropped_total{reason="hold_budget_exceeded"} > 0 and on (pod, instance) (time() - process_start_time_seconds{pod=~"log-router-.*"} < 900)) > 0 or sum by (tenant) (increase(log_router_events_dropped_total{reason="hold_budget_exceeded"}[15m])) > 0
    labels:
      context: log-router
      dashboard: hermes-log-router
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-log-router"
      service: hermes
      severity: critical
      support_group: observability
      tier: os
      meta: "Log Router dropped held audit events of project {{`{{ $labels.tenant }}`}}: data loss"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Log Router dropped about {{`{{ $value | humanize }}`}} held audit events of project {{`{{ $labels.tenant }}`}} because a hold budget was full. This is real data loss: the events were accepted and are gone. Their writes have been failing on our side for a long time. Fix the write (writer role in the project, storage reachable) so the remaining held events get delivered, and check whether the hold budgets and WAL volume are too small."
      summary: "Log Router lost held events of project {{`{{ $labels.tenant }}`}}"

  # Later drops start from the 0 series log-router creates when a tenant gets held. Startup recovery
  # counts before the first scrape, which increase() cannot see: any count of a process younger than 1h counts too.
  - alert: OpenstackHermesLogRouterWALUndecodable
    expr: sum by (tenant) (log_router_events_dropped_total{reason="wal_undecodable"} > 0 and on (pod, instance) (time() - process_start_time_seconds{pod=~"log-router-.*"} < 3600)) > 0 or sum by (tenant) (increase(log_router_events_dropped_total{reason="wal_undecodable"}[1h])) > 0
    labels:
      context: log-router
      dashboard: hermes-log-router
      persesDashboard: "https://perses.{{ .Values.global.region }}.{{ .Values.global.tld }}/projects/observability/dashboards/hermes-log-router"
      service: hermes
      severity: warning
      support_group: observability
      tier: os
      meta: "Log Router removed WAL entries of project {{`{{ $labels.tenant }}`}} it could not decode"
      playbook: "docs/devops/alert/hermes"
    annotations:
      description: "Log Router removed about {{`{{ $value | humanize }}`}} events of project {{`{{ $labels.tenant }}`}} from its WAL because they could not be decoded. These events were accepted and are lost. This is a log-router bug or a damaged WAL volume, not a customer problem. Check the log-router logs for 'cannot be decoded' and the health of the WAL volume."
      summary: "Log Router lost undecodable WAL entries of project {{`{{ $labels.tenant }}`}}"
{{- end }}
