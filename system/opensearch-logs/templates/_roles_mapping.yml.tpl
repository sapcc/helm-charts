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
  backend_roles:
  - CC_IAS_TEAM_SUPERVISION

data:
  reserved: false
  users:
  - "data"

syslog:
  reserved: false
  users:
  - "syslog"

jump:
  reserved: false
  users:
  - "jump"

logstash:
  reserved: false
  backend_roles:
  - "logstash"

jaeger:
  reserved: false
  users:
  - "jaeger"

complex-role:
  reserved: false
  hidden: false
  backend_roles:
  - CC_IAS_TEAM_SUPERVISION
  - CC_IAS_OPERATIONS_UI_KIBANA_SUPPORT

kibana_user:
  reserved: false
  backend_roles:
  - CC_IAS_OPERATIONS_UI_KIBANA_SUPPORT

ml_full_access:
  reserved: true
  backend_roles:
  - CC_IAS_OPERATIONS_UI_KIBANA_SUPPORT

mlrole:
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

promrole:
  reserved: false
  users:
  - "promuser"

jupyterhub:
  reserved: false
  users:
  - "jupyterhub"

maillog:
  reserved: false
  users:
  - "maillog"
