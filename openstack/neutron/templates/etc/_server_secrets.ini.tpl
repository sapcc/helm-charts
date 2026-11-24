{{- $name := required "No defaultUser defined in service_users" .Values.service_users.defaultUser }}
{{- $creds := required (printf "No user '%s' in service_users.users" $name) (index .Values.service_users.users $name) }}

[nova]
username = {{ $creds.username | include "resolve_secret" }}
password = {{ $creds.password | include "resolve_secret" }}

[designate]
username = {{ $creds.username | include "resolve_secret" }}
password = {{ $creds.password | include "resolve_secret" }}

[placement]
username = {{ $creds.username | include "resolve_secret" }}
password = {{ $creds.password | include "resolve_secret" }}

[database]
connection = {{ include "utils.db_url" . }}

{{- include "ini_sections.audit_middleware_notifications" . }}
