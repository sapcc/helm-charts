{{- define "tempest-base.cc_slack_url" }}
{{ (index .Values.tempest_slack_webhook_url (index (split "-" .Chart.Name)._0))  | include "tempest-base.resolve_secret" }}
{{ end }}
