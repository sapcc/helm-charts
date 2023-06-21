groups:
- name: volume.alerts
  rules:
  - alert: {{ include "alerts.name_prefix" . }}PostgresVolumeNearlyFull
    {{- $pvc := .Values.persistence.existingClaim | default (include "fullname" .) }}
    expr: kubelet_volume_stats_available_bytes{persistentvolumeclaim="{{ $pvc }}"}/kubelet_volume_stats_capacity_bytes{persistentvolumeclaim="{{ $pvc }}"} < 0.05
    for: 10m
    labels:
      context: volumefull
      service: {{ include "alerts.service" . }}
      severity: info
      support_group: {{ required ".Values.alerts.support_group missing" .Values.alerts.support_group }}
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: |
        The PhysicalVolume for the {{ template "fullname" . }} database is more than 95% full. Try running a full vacuum
        to reclaim disk space. If that does not help, check if space can be reclaimed on the application level, e.g. by
        running garbage collection (if available). If that does not help, the PhysicalVolume needs to be resized.
      summary: {{ template "fullname" . }} DB volume is almost full
