- name: mysql.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}MariaDBTooManyConnections
    expr: (mysql_global_variables_max_connections{app_kubernetes_io_instance=~"{{ include "fullName" . }}"} - mysql_global_status_threads_connected{app_kubernetes_io_instance=~"{{ include "fullName" . }}"} < 200)
    for: 10m
    labels:
      context: datbase
      service: {{ include "alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: {{ include "fullName" . }} has too many connections open. Please check the service containers.
      summary: {{ include "fullName" . }} has too many connections open.

  - alert: {{ include "alerts.service" . | title }}MariaDBSlowQueries
    expr: (delta(mysql_global_status_slow_queries{app_kubernetes_io_instance=~"{{ include "fullName" . }}"}[8m]) > 3)
    for: 10m
    labels:
      context: database
      service: {{ include "alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
      playbook: 'docs/support/playbook/database/MariaDBSlowQueries'
    annotations:
      description: {{ include "fullName" . }} has reported slow queries. Please check the DB.
      summary: {{ include "fullName" . }} reports slow queries.

  - alert: {{ include "alerts.service" . | title }}MariaDBWaitingForLock
    expr: (mysql_info_schema_processlist_seconds{app_kubernetes_io_instance=~"{{ include "fullName" . }}", state=~"waiting for lock"} / 1000  > 15)
    for: 10m
    labels:
      context: database
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: {{ include "fullName" . }} has queries waiting for lock more than 15 sec. Deadlock possible.
      summary: {{ include "fullName" . }} has queries waiting for lock.

  - alert: {{ include "alerts.service" . | title }}MariaDBHighRunningThreads
    expr: (mysql_global_status_threads_running{app_kubernetes_io_instance=~"{{ include "fullName" . }}"} > 20)
    for: 10m
    labels:
      context: database
      service: {{ include "alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
      playbook: 'docs/support/playbook/manila/mariadb_high_running_threads'
    annotations:
      description: {{ include "fullName" . }} has more than 20 running threads.
      summary: {{ include "fullName" . }} running threads high.

  - alert: {{ include "alerts.service" . | title }}MariaDBBufferPoolNearlyFull
    expr: >-
      (
        mysql_global_status_buffer_pool_pages{state="free", app_kubernetes_io_instance=~"{{ include "fullName" . }}"}
        / ignoring(state)
        sum without(state) (
          mysql_global_status_buffer_pool_pages{state=~"data|free|misc", app_kubernetes_io_instance=~"{{ include "fullName" . }}"}
        )
        < 0.10
      )
    for: 30m
    labels:
      context: database
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
      playbook: 'docs/support/playbook/database/MariaDBBufferPool'
    annotations:
      description: >-
        {{ include "fullName" . }} InnoDB buffer pool has less than 10% free pages.
        The buffer pool is filling up and performance will degrade soon.
        Consider increasing innodb_buffer_pool_size.
      summary: {{ include "fullName" . }} InnoDB buffer pool is nearly full (< 10% free pages).

  - alert: {{ include "alerts.service" . | title }}MariaDBBufferPoolExhausted
    expr: >-
      (
        mysql_global_status_buffer_pool_pages{state="free", app_kubernetes_io_instance=~"{{ include "fullName" . }}"}
        / ignoring(state)
        sum without(state) (
          mysql_global_status_buffer_pool_pages{state=~"data|free|misc", app_kubernetes_io_instance=~"{{ include "fullName" . }}"}
        )
        < 0.025
      )
    for: 15m
    labels:
      context: database
      service: {{ include "alerts.service" . }}
      severity: critical
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
      playbook: 'docs/support/playbook/database/MariaDBBufferPool'
    annotations:
      description: >-
        {{ include "fullName" . }} InnoDB buffer pool has less than 2.5% free pages and is effectively exhausted.
        InnoDB must evict pages on every read, causing heavy disk I/O and severe query performance degradation.
        Increase innodb_buffer_pool_size immediately and restart the MariaDB pod.
      summary: {{ include "fullName" . }} InnoDB buffer pool is exhausted (< 2.5% free pages).

