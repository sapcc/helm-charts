- name: pxc.alerts
  rules:
  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterDBTooManyConnections
    expr: (mysql_global_variables_max_connections{app=~"{{ include "pxc-db.fullname" . }}"} - mysql_global_status_threads_connected{app=~"{{ include "pxc-db.fullname" . }}"} < 200)
    for: 10m
    labels:
      context: datbase
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: {{ include "pxc-db.fullname" . }} has too many connections open. Please check the service containers.
      summary: {{ include "pxc-db.fullname" . }} has too many connections open.

  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterDBSlowQueries
    expr: (rate(mysql_global_status_slow_queries{app=~"{{ include "pxc-db.fullname" . }}"}[5m]) > 0)
    for: 10m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: 'docs/support/playbook/database/MariaDBSlowQueries'
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: {{ include "pxc-db.fullname" . }} has reported slow queries. Please check the DB.
      summary: {{ include "pxc-db.fullname" . }} reports slow queries.

  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterDBWaitingForLock
    expr: (mysql_info_schema_processlist_seconds{app=~"{{ include "pxc-db.fullname" . }}", state=~"waiting for lock"} / 1000  > 20)
    for: 10m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: {{ include "pxc-db.fullname" . }} has queries waiting for lock more than 20 sec. Deadlock possible.
      summary: {{ include "pxc-db.fullname" . }} has queries waiting for lock.

  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterDBHighRunningThreads
    expr: (mysql_global_status_threads_running{app=~"{{ include "pxc-db.fullname" . }}"} > 20)
    for: 10m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: 'docs/support/playbook/manila/mariadb_high_running_threads'
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: {{ include "pxc-db.fullname" . }} has more than 20 running threads.
      summary: {{ include "pxc-db.fullname" . }} running threads high.

  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterIncomplete
    expr: (mysql_global_status_wsrep_cluster_size{app=~"{{ include "pxc-db.fullname" . }}"} < {{ .Values.pxc.size }})
    for: 10m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: ''
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: {{ include "pxc-db.fullname" . }} reports cluster size of less than 3 nodes.
      summary: {{ include "pxc-db.fullname" . }} cluster incomplete.

  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterInnoDBLogWaits
    expr: (rate(mysql_global_status_innodb_log_waits{app=~"{{ include "pxc-db.fullname" . }}"}[10m]) > 10)
    for: 10m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: ''
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: {{ include "pxc-db.fullname" . }} InnoDB log writes stalling.
      summary: {{ include "pxc-db.fullname" . }} has problem writing to disk.

  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterNodeNotReady
    expr: (mysql_global_status_wsrep_ready{app=~"{{ include "pxc-db.fullname" . }}"} != 1)
    for: 10m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: ''
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: {{ include "pxc-db.fullname" . }} Cluster node not ready.
      summary: {{ include "pxc-db.fullname" . }} reports as not ready.

  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterNodeNotSynced
    expr: (mysql_global_variables_wsrep_desync{app=~"{{ include "pxc-db.fullname" . }}"} != 0)
    for: 10m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: ''
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: {{ include "pxc-db.fullname" . }} Cluster node out of sync.
      summary: {{ include "pxc-db.fullname" . }} reports as not synced.

  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterNodeSyncDelayed
    expr: (mysql_global_status_wsrep_local_recv_queue_avg{app="{{ include "pxc-db.fullname" . }}"} > 0.5)
    for: 30m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: ''
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: "{{ include "pxc-db.fullname" . }} Galera cluster reports at least 1 node with substantial replication delay in the last 30 minutes"
      summary: "{{ include "pxc-db.fullname" . }} Galera cluster node sync delayed"

  - alert: {{ include "pxc-db.alerts.service" . | camelcase }}GaleraClusterNodeReplicationPaused"
    expr: (mysql_global_status_wsrep_flow_control_paused{app="{{ include "pxc-db.fullname" . }}"} > 0.25)
    for: 30m
    labels:
      context: database
      service: {{ include "pxc-db.alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      playbook: ''
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: "{{ include "pxc-db.fullname" . }} Galera cluster reports at least 1 node with 25% paused replication in the last 30 minutes"
      summary: "{{ include "pxc-db.fullname" . }} Galera cluster node replication paused"
