groups:
- name: pvc-usage.alerts
  rules:
  - alert: HighPVCUsagePredicted
    expr: sum((pvc_usage* 100 > 70) and (predict_linear(pvc_usage[1d], 7 * 24 * 3600) * 100 > 90 )) by (persistentvolumeclaim, mountedby, volumename)
    for: 1h
    labels:
      tier: k8s
      service: resources
      severity: warning
      context: storage
      meta: "PVC {{`{{ $labels.persistentvolumeclaim }}`}} is predicted to exceed 90% storage consumption in the next 7 days"
      playbook: '/docs/support/playbook/kubernetes/pvc_usage.html'
      no_alert_on_absence: "true"
    annotations:
      description: "The PVC {{`{{ $labels.persistentvolumeclaim }}`}} mounted by {{`{{ $labels.mountedby }}`}} with volume name {{`{{ $labels.volumename }}`}} is predicted to exceed 90% storage consumption in the next 7 days"
      summary: "PVC {{`{{ $labels.persistentvolumeclaim }}`}} is predicted to exceed 90% storage consumption in the next 7 days"
