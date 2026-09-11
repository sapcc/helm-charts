- name: volume.alerts
  rules:
  - alert: {{ include "alerts.service" . | title }}MariaDBVolumeNearlyFull
    {{- $pvc := include "mariadb.dataPvcName" . }}
    expr: (kubelet_volume_stats_available_bytes{persistentvolumeclaim="{{ $pvc }}"} / kubelet_volume_stats_capacity_bytes{persistentvolumeclaim="{{ $pvc }}"}) < {{ .Values.alerts.pvc_free_threshold }}
    for: 10m
    labels:
      context: database
      service: {{ include "alerts.service" . }}
      severity: warning
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
    annotations:
      description: The {{ include "fullName" . }} data volume has less than {{ mulf .Values.alerts.pvc_free_threshold 100 }}% free space left. If it fills up, MariaDB stops accepting writes.
      summary: {{ include "fullName" . }} data volume is running low on free space.
