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
  - "CCADMIN_DOMAIN_USERS"

data:
  reserved: false
  users:
  - "data"

logstash:
  reserved: false
  backend_roles:
  - "logstash"

complex-role:
  reserved: false
  hidden: false
  backend_roles:
  - "CCADMIN_DOMAIN_USERS"

kibana_user:
  reserved: false
  backend_roles:
  - "CCADMIN_DOMAIN_USERS"
  - "CCADMIN_MONITORING_USERS"
  description: "Maps kibanauser to kibana_user"

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
