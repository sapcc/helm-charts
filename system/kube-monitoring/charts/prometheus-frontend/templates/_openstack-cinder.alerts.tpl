### Cinder Alerts ###

ALERT OpenstackCinderVolumeStuck
  IF sum(openstack_stuck_volumes_count_gauge) by (host,status) > 0
  FOR 5m
  LABELS {
    service = "cinder",
    severity = "info",
    tier = "openstack",
    dashboard = "cinder",
    meta = "{{`{{ $value }}`}} volumes stuck",
    {{ if .Values.ops_docu_url -}}
      playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/volumes.html",
    {{- end }}
  }
  ANNOTATIONS {
    summary = "Cinder Volumes in stuck state",
    description = "Sum of Openstack Cinder Volume Stuck is more than 1",
  }

ALERT OpenstackCinderVolumeAttach
  IF max(openstack_stuck_volumes_max_duration_gauge{status="attaching"}) by (host) > 15
  FOR 5m
  LABELS {
    service = "cinder",
    severity = "info",
    tier = "openstack",
    dashboard = "cinder",
    meta = "{{`{{ $labels.host }}`}} has volumes stuck in attach state",
    {{ if .Values.ops_docu_url -}}
      playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/volumes.html",
    {{- end }}
  }
  ANNOTATIONS {
    summary = "Cinder Volumes taking more than 15s to attach",
    description = "Cinder Volumes taking more than 15s to attach in {{`{{ $labels.host }}`}}",
  }

ALERT OpenstackCinderVolumeDetach
  IF max(openstack_stuck_volumes_max_duration_gauge{status="detaching"}) by (host) > 10
  FOR 5m
  LABELS {
    service = "cinder",
    severity = "info",
    tier = "openstack",
    dashboard = "cinder",
    meta = "{{`{{ $labels.host }}`}} has volumes stuck in detach state",
    {{ if .Values.ops_docu_url -}}
      playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/volumes.html",
    {{- end }}
  }
  ANNOTATIONS {
    summary = "Cinder Volumes taking more than 10s to detach",
    description = "Cinder Volumes taking more than 10s to detach in {{`{{ $labels.host }}`}}",
  }
