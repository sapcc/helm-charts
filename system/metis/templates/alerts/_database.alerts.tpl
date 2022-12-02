- name: metisdb.alerts
  rules:
    - alert: MetisDBHighPVCUsage
      expr: sum by(persistentvolumeclaim) ((kubelet_volume_stats_used_bytes{persistentvolumeclaim="metis-pvclaim"}/kubelet_volume_stats_capacity_bytes{persistentvolumeclaim="metis-pvclaim"} * 100 > 70) and ( predict_linear(kubelet_volume_stats_used_bytes{persistentvolumeclaim="metis-pvclaim"}[1d], 7 * 24 * 3600) / predict_linear(kubelet_volume_stats_capacity_bytes{persistentvolumeclaim="metis-pvclaim"}[1d], 7 * 24 * 3600)*100 > 90))
      for: 15m
      labels:
        context: storage
        service: metis
        severity: info
        support_group: {{ required "$.Values.mariadb.alerts.support_group missing" $.Values.mariadb.alerts.support_group}}
      annotations:
        description: High PVC usage of 'metis-pvclaim'
        summary: MetisDB pvc is almost full
