- name: mariadb.alerts
  rules:
  - alert: "{{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | title }}MariaDBHighConnectionCount"
    expr: (mysql_global_variables_max_connections{app="{{ $.Release.Name }}", pod=~"{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}.*"} - mysql_global_status_threads_connected{app="{{ $.Release.Name }}", pod=~"{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}.*"} < 200)
    for: 10m
    labels:
      context: "database"
      service: {{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | quote }}
      severity: "info"
      tier: {{ required "$.Values.monitoring.prometheus.alerts missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.tier | quote }}
      support_group: {{ required "$.Values.monitoring.prometheus.alerts.support_group missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.support_group | quote }}
    annotations:
      description: "At least one {{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} database node has lot of open connections for at least 10 minutes"
      summary: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} has lot of open connections"
  - alert: "{{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | title }}MariaDBSlowQueries"
    expr: (delta(mysql_global_status_slow_queries{app="{{ $.Release.Name }}", pod=~"{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}.*"}[8m]) > 3)
    for: 10m
    labels:
      context: "database"
      service: {{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | quote }}
      severity: "info"
      tier: {{ required "$.Values.monitoring.prometheus.alerts missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.tier | quote }}
      support_group: {{ required "$.Values.monitoring.prometheus.alerts.support_group missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.support_group | quote }}
      playbook: 'docs/support/playbook/database/MariaDBSlowQueries'
    annotations:
      description: "At least one {{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} database node reports slow queries in the last 10 minutes"
      summary: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} reports slow queries"
  - alert: "{{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | title }}MariaDBWaitingForLock"
    expr: (mysql_info_schema_processlist_seconds{app="{{ $.Release.Name }}", pod=~"{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}.*", state=~"waiting for lock"} / 1000  > 15)
    for: 10m
    labels:
      context: "database"
      service: {{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | quote }}
      severity: "warning"
      tier: {{ required "$.Values.monitoring.prometheus.alerts missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.tier | quote }}
      support_group: {{ required "$.Values.monitoring.prometheus.alerts.support_group missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.support_group | quote }}
    annotations:
      description: "At least one {{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} database node has queries waiting for a lock for more than 15 sec. Deadlock possible"
      summary: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} has queries waiting for lock"
  - alert: "{{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | title }}MariaDBHighRunningThreads"
    expr: (mysql_global_status_threads_running{app="{{ $.Release.Name }}", pod=~"{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}.*"} > 20)
    for: 10m
    labels:
      context: "database"
      service: {{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | quote }}
      severity: "info"
      tier: {{ required "$.Values.monitoring.prometheus.alerts missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.tier | quote }}
      support_group: {{ required "$.Values.monitoring.prometheus.alerts.support_group missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.support_group | quote }}
      playbook: 'docs/support/playbook/manila/mariadb_high_running_threads'
    annotations:
      description: "At least one {{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} database node has more than 20 running threads in the last 10 minutes"
      summary: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} has a lot of running threads"
  - alert: "{{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | title }}MariaDBInnoDBLogWaits"
    expr: (rate(mysql_global_status_innodb_log_waits{app="{{ $.Release.Name }}", pod=~"{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}.*"}[10m]) > 10)
    for: 10m
    labels:
      context: "database"
      service: {{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | quote }}
      severity: "warning"
      tier: {{ required "$.Values.monitoring.prometheus.alerts missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.tier | quote }}
      support_group: {{ required "$.Values.monitoring.prometheus.alerts.support_group missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.support_group | quote }}
    annotations:
      description: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} MariaDB reports InnoDB log writes delays in the last 10 minutes"
      summary: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} MariaDB has problems writing to disk"
- name: galera.alerts
  rules:
  - alert: "{{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | title }}GaleraClusterIncomplete"
    expr: (mysql_global_status_wsrep_cluster_size{app="{{ $.Release.Name }}", pod=~"{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}.*"} < {{ ((include "replicaCount" (dict "global" $ "type" "database")) | int) }})
    for: 30m
    labels:
      context: "database"
      service: {{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | quote }}
      severity: "warning"
      tier: {{ required "$.Values.monitoring.prometheus.alerts missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.tier | quote }}
      support_group: {{ required "$.Values.monitoring.prometheus.alerts.support_group missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.support_group | quote }}
    annotations:
      description: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} Galera cluster reports less than {{ ((include "replicaCount" (dict "global" $ "type" "database")) | int) }} nodes for the last 30 minutes"
      summary: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} Galera cluster incomplete"
  - alert: "{{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | title }}GaleraClusterNodeNotReady"
    expr: (mysql_global_status_wsrep_ready{app="{{ $.Release.Name }}", pod=~"{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}.*"} != 1)
    for: 30m
    labels:
      context: "database"
      service: {{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | quote }}
      severity: "warning"
      tier: {{ required "$.Values.monitoring.prometheus.alerts missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.tier | quote }}
      support_group: {{ required "$.Values.monitoring.prometheus.alerts.support_group missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.support_group | quote }}
    annotations:
      description: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} Galera cluster reports at least 1 not ready node for the last 30 minutes"
      summary: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} Galera cluster node not ready"
  - alert: "{{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | title }}GaleraClusterNodeNotSynced"
    expr: (mysql_global_variables_wsrep_desync{app="{{ $.Release.Name }}", pod=~"{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}.*"} != 0)
    for: 30m
    labels:
      context: "database"
      service: {{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | quote }}
      severity: "warning"
      tier: {{ required "$.Values.monitoring.prometheus.alerts missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.tier | quote }}
      support_group: {{ required "$.Values.monitoring.prometheus.alerts.support_group missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.support_group | quote }}
    annotations:
      description: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} Galera cluster reports at least 1 desynced node for the last 30 minutes"
      summary: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} Galera cluster node not in sync"
  - alert: "{{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | title }}GaleraClusterNodeSyncDelayed"
    expr: (mysql_global_status_wsrep_local_recv_queue_avg{app="{{ $.Release.Name }}", pod=~"{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}.*"} > 0.5)
    for: 30m
    labels:
      context: "database"
      service: {{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | quote }}
      severity: "warning"
      tier: {{ required "$.Values.monitoring.prometheus.alerts missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.tier | quote }}
      support_group: {{ required "$.Values.monitoring.prometheus.alerts.support_group missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.support_group | quote }}
    annotations:
      description: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} Galera cluster reports at least 1 node with substantial replication delay in the last 30 minutes"
      summary: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} Galera cluster node sync delayed"
  - alert: "{{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | title }}GaleraClusterNodeSyncDelayed"
    expr: (mysql_global_status_wsrep_flow_control_paused{app="{{ $.Release.Name }}", pod=~"{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}.*"} > 0.25)
    for: 30m
    labels:
      context: "database"
      service: {{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | quote }}
      severity: "warning"
      tier: {{ required "$.Values.monitoring.prometheus.alerts missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.tier | quote }}
      support_group: {{ required "$.Values.monitoring.prometheus.alerts.support_group missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.support_group | quote }}
    annotations:
      description: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} Galera cluster reports at least 1 node with 25% paused replication in the last 30 minutes"
      summary: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} Galera cluster node replication paused"
