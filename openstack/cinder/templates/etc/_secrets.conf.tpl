{{- $serviceUserKey := .Values.service_users.defaultUser | required "service_users.defaultUser is missing" }}
{{- $serviceUser := index .Values.service_users.users $serviceUserKey | required (printf "'service_users.users' is missing key '%s' defined as 'defaultUser'" $serviceUserKey) }}
{{- $serviceUserName := $serviceUser.username | required (printf "'service_users.users.%s.username' is required" $serviceUserKey) }}
{{- $serviceUserPassword := $serviceUser.password | required (printf "'service_users.users.%s.password' is required" $serviceUserKey) }}
[DEFAULT]
{{- template "ini_sections.default_transport_url" . }}

{{- include "ini_sections.database" . }}

{{- include "osprofiler" . }}

[keystone_authtoken]
username = {{ $serviceUserName | include "resolve_secret" }}
password = {{ $serviceUserPassword | include "resolve_secret" }}

[service_user]
username = {{ $serviceUserName | include "resolve_secret" }}
password = {{ $serviceUserPassword | include "resolve_secret" }}

[nova]
username = {{ $serviceUserName | include "resolve_secret" }}
password = {{ $serviceUserPassword | include "resolve_secret" }}

{{- include "ini_sections.audit_middleware_notifications" . }}
