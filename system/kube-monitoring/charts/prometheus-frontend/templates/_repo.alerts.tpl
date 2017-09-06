ALERT OpenstackRepo
  IF repo_sync_last_run_gauge{kind="success"} < 1
  FOR 2d
  LABELS {
    tier = "openstack",
    service = "swift",
    severity = "warning",
    context = "repo",
    meta = "{{`{{ $labels.repo }}`}}",
    dashboard = "repo-sync?var-repo={{`{{ $labels.repo }}`}}",
  }
  ANNOTATIONS {
    summary = "Repo {{`{{ $labels.repo }}`}} sync failed",
    description = "Content repo {{`{{ $labels.repo }}`}} sync failed. Check the logs.",
  }

ALERT OpenstackRepoEntitlementForbidden
  IF repo_sync_check_success_gauge == -1
  FOR 1h
  LABELS {
    tier = "openstack",
    service = "swift",
    severity = "warning",
    context = "repo-{{`{{ $labels.repo }}`}}-entitlement",
    meta = "{{`{{ $labels.repo }}`}}",
    dashboard = "repo-sync?var-repo={{`{{ $labels.repo }}`}}",
    {{ if .Values.ops_docu_url -}}
      playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/repo_{{`{{ $labels.repo }}`}}_entitlement.html",
    {{- end }}
  }
  ANNOTATIONS {
    summary = "Repo {{`{{ $labels.repo }}`}} entitlement lost",
    description = "Repo {{`{{ $labels.repo }}`}} the entitlement became invalid.",
  }

ALERT OpenstackRepoEntitlement
  IF repo_sync_check_success_gauge == 0
  FOR 1h
  LABELS {
    tier = "openstack",
    service = "swift",
    severity = "info",
    context = "repo-{{`{{ $labels.repo }}`}}-entitlement",
    meta = "{{`{{ $labels.repo }}`}}",
    dashboard = "repo-sync?var-repo={{`{{ $labels.repo }}`}}",
  }
  ANNOTATIONS {
    summary = "Repo {{`{{ $labels.repo }}`}} entitlement check failed",
    description = "Repo {{`{{ $labels.repo }}`}} entitlement check failed. Check the logs.",
  }
