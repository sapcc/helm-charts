- name: kubernetes.alerts
  rules:
  - alert: "{{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | title }}DBClusterNodeNotReady"
    expr: (sum(kube_pod_status_ready_normalized{ condition="true", pod=~"{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }}.*" }) < {{ ((include "replicaCount" (dict "global" $ "type" "database")) | int) }})
    for: 30m
    labels:
      context: "availability"
      service: {{ $.Values.monitoring.prometheus.alerts.service | default $.Values.mariadb.galera.clustername | quote }}
      severity: "warning"
      tier: {{ required "$.Values.monitoring.prometheus.alerts missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.tier | quote }}
      support_group: {{ required "$.Values.monitoring.prometheus.alerts.support_group missing, but required for Prometheus alert definitions" $.Values.monitoring.prometheus.alerts.support_group | quote }}
      playbook: "docs/support/playbook/database/mariadbgalera_clusternode_not_ready/"
    annotations:
      description: "At least one {{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} database cluster pod is not ready since 30 minutes or more."
      summary: "{{ (include "nodeNamePrefix" (dict "global" $ "component" "database")) }} cluster pod(s) not ready"
