---
# In this file users, backendroles and hosts can be mapped to Security roles.
# Permissions for OpenSearch roles are configured in roles.yml

_meta:
  type: "rolesmapping"
  config_version: 2

# Define your roles mapping here

## Demo roles mapping

adminrole:
  reserved: false
  users:
  -  "admin"
  -  "admin2"
  backend_roles:
  - CC_IAS_TEAM_SUPERVISION

anonymous_health_role:
  backend_roles:
  - "opendistro_security_anonymous_backendrole"

audit:
  reserved: false
  users:
  - "audit"
  - "audit2"
awx:
  reserved: false
  users:
  - "awx"
  - "awx2"

complex-role:
  reserved: false
  hidden: false
  backend_roles:
  - CC_IAS_OPERATIONS_UI_KIBANA_SUPPORT

compute:
  reserved: false
  users:
  - "compute"
  - "compute2"

data:
  reserved: false
  users:
  - "data"
  - "data2"

jaeger:
  reserved: false
  users:
  - "jaeger"
  - "jaeger2"

jump:
  reserved: false
  users:
  - "jump"
  - "jump2"

jupyterhub:
  reserved: false
  users:
  - "jupyterhub"
  - "jupyterhub2"

kibana_server:
  reserved: true
  users:
  - "kibanaserver"
  - "kibanaserver2"

kibana_user:
  reserved: false
  backend_roles:
  - CC_IAS_OPERATIONS_UI_KIBANA_SUPPORT

maillog:
  reserved: false
  users:
  - "maillog"
  - "maillog2"

manage_snapshots:
  reserved: false
  backend_roles:
  - "snapshotrestore"

promrole:
  reserved: false
  users:
  - "promuser"
  - "promuser2"
{{- if .Values.qalogs.enabled }}
  - "ronly"
  - "ronly2"
{{- end }}
  backend_roles:
  - CC_IAS_OPERATIONS_UI_KIBANA_SUPPORT

readall:
  reserved: false
  backend_roles:
  - "readall"

storage:
  reserved: false
  users:
  - "storage"
  - "storage2"

{{- if .Values.qalogs.enabled }}
otel:
  reserved: false
  users:
  - "otel"
  - "otel2"
{{- end }}
