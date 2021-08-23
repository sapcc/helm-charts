groups:
- name: volume.alerts
  rules:
  - alert: {{ include "alerts.name_prefix" . }}PostgresVolumeNearlyFull
    {{- $pvc := .Values.persistence.existingClaim | default (include "fullname" .) }}
    expr: pvc_usage{persistentvolumeclaim="{{ $pvc }}"} > 0.95
    for: 10m
    labels:
      context: volumefull
      service: {{ include "alerts.service" . }}
      severity: info
      tier: {{ required ".Values.alerts.tier missing" .Values.alerts.tier }}
    annotations:
      description: |
        The PhysicalVolume for the {{ template "fullname" . }} database is more than 95% full. Try running a full vacuum
        to reclaim disk space. If that does not help, the PhysicalVolume needs to be resized.
      summary: {{ template "fullname" . }} DB volume is almost full
