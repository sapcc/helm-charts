- name: datahubrestore.alerts
  rules:
  - alert: DatahubDBRestoreIncomplete
    expr: kube_job_failed{namespace="datahub", condition="true"} == 1
    for: 5m
    labels:
      severity: info
      tier: os
      service: metis
    annotations:
      description: "Restore of Openstack DB backups into datahubdb failed. Check job logs."
      summary: Restore of Openstack DB backups into datahubdb failed. Check job logs."