### Manila Alerts ###

ALERT OpenstackManilaSharesStuck
  IF (sum(openstack_manila_shares_stuck_count_gauge) by (host,status)) > 0
  FOR 5m
  LABELS {
    service = "manila",
    severity = "info",
    tier = "openstack",
    dashboard = "manila",
    meta = "{{`{{ $value }}`}} shares",
    {{ if .Values.ops_docu_url -}}
      playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/shares_stuck.html",
    {{- end }}
  }
  ANNOTATIONS {
    summary = "Manila shares in stuck state",
    description = "Sum of Openstack Manila Shares Stuck is more than 1",
  }

ALERT OpenstackManilaSharesStuckCreate
  IF max(openstack_manila_shares_stuck_max_duration_gauge{status="creating"}) by (host) > 15
  FOR 5m
  LABELS {
    service = "manila",
    severity = "info",
    tier = "openstack",
    dashboard = "manila",
    meta = "{{`{{print minute($value) .}}`}} minute(s)",
    {{ if .Values.ops_docu_url -}}
      playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/shares_stuck.html",
    {{- end }}
  }
  ANNOTATIONS {
    summary = "Manila Shares taking more than 15 minutes to create",
    description = "Manila Shares taking more than 15 minutes to create in {{`{{ $labels.host }}`}}",
  }

ALERT OpenstackManilaSharesStuckDelete
  IF max(openstack_manila_shares_stuck_max_duration_gauge{status="deleting"}) by (host) > 15
  FOR 5m
  LABELS {
    service = "manila",
    severity = "info",
    tier = "openstack",
    dashboard = "manila",
    meta = "{{`{{day_of_month(vector($value))-1}}`}} day(s) {{`{{hour(vector($value))}}`}} hour(s) {{`{{minute(vector($value))}}`}} minute(s)",
    {{ if .Values.ops_docu_url -}}
      playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/shares_stuck.html",
    {{- end }}
  }
  ANNOTATIONS {
    summary = "Manila Shares taking more than 15 minutes to delete",
    description = "Manila Shares taking more than 15 minutes to delete in {{`{{ $labels.host }}`}}",
  }
