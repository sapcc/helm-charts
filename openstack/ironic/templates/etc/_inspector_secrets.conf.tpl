[DEFAULT]
{{- include "ini_sections.default_transport_url" . }}

[ironic]
username = {{ include "ironic.helpers.service_user_username" . | include "resolve_secret" }}
password = {{ include "ironic.helpers.service_user_password" . | include "resolve_secret" }}

[database]
{{- if eq .Values.dbType "mariadb" }}
connection = {{ tuple . .Values.mariadb.users.ironic_inspector.name .Values.mariadb.users.ironic_inspector.name .Values.mariadb.users.ironic_inspector.password | include "utils._db_url_mariadb" }}
{{- else if eq .Values.dbType "pxc-db" }}
connection = {{ tuple . .Values.pxc_db.users.ironic_inspector.name .Values.pxc_db.users.ironic_inspector.name .Values.pxc_db.users.ironic_inspector.password | include "utils._db_url_pxc_db" }}
{{- else }}
{{ fail "Unknown database type" }}
{{- end }}

[keystone_authtoken]
username = {{ include "ironic.helpers.service_user_username" . | include "resolve_secret" }}
password = {{ include "ironic.helpers.service_user_password" . | include "resolve_secret" }}

{{- include "ini_sections.audit_middleware_notifications" . }}
