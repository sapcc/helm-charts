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

data:
  reserved: false
  users:
  - "data"
  - "data2"

audit:
  reserved: false
  users:
  - "audit"
  - "audit2"

jump:
  reserved: false
  users:
  - "jump"
  - "jump2"

logstash:
  reserved: false
  users:
  - "logstash"

storage:
  reserved: false
  users:
  - "storage"
  - "storage2"

compute:
  reserved: false
  users:
  - "compute"
  - "compute2"

awx:
  reserved: false
  users:
  - "awx"
  - "awx2"

otel:
  reserved: false
  users:
  - "otel"
  - "otel2"

jaeger:
  reserved: false
  users:
  - "jaeger"
  - "jaeger2"

complex-role:
  reserved: false
  hidden: false
  backend_roles:
  - CC_IAS_OPERATIONS_UI_KIBANA_SUPPORT

kibana_user:
  reserved: false
  backend_roles:
  - CC_IAS_OPERATIONS_UI_KIBANA_SUPPORT

readall:
  reserved: false
  backend_roles:
  - "readall"

manage_snapshots:
  reserved: false
  backend_roles:
  - "snapshotrestore"

kibana_server:
  reserved: true
  users:
  - "kibanaserver"
  - "kibanaserver2"

promrole:
  reserved: false
  users:
  - "promuser"
  - "promuser2"
  - "ronly"
  - "ronly2"
  backend_roles:
  - CC_IAS_OPERATIONS_UI_KIBANA_SUPPORT

auditorrole:
  reserved: false
  users:
  - "alerting"
  - "alerting2"

jupyterhub:
  reserved: false
  users:
  - "jupyterhub"
  - "jupyterhub2"

maillog:
  reserved: false
  users:
  - "maillog"
  - "maillog2"

oraboskvmrole:
  reserved: false	
  users:
  - "oraboskvm"
  - "oraboskvm2"

syslog:
  reserved: false
  users:
  - "syslog"
  - "syslog2"

anonymous_health_role:
  backend_roles:
  - "opendistro_security_anonymous_backendrole"

security_analytics_full_access:
  reserved: false
  backend_roles:
  - CC_IAS_OPERATIONS_UI_KIBANA_SUPPORT
