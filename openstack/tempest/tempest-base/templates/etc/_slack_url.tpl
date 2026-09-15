{{- define "tempest-base.slack_url" }}
{{ .Values.tempest_slack_webhook_url.tempest_tests | include "tempest-base.resolve_secret" }}
{{ end }}
