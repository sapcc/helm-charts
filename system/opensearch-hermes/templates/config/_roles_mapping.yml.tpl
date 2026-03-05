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
  {{- range .Values.global.ldap.opensearch_admin_groups }}
  - {{ . | title }}
  {{- end }}

complex-role:
  reserved: false
  hidden: false
  backend_roles:
  {{- range .Values.global.ldap.opensearch_admin_groups }}
  - {{ . | title }}
  {{- end }}
  {{- range .Values.global.ldap.opensearch_dashboard_groups }}
  - {{ . | title }}
  {{- end }}

kibana_user:
  reserved: false
  backend_roles:
  {{- range .Values.global.ldap.opensearch_dashboard_groups }}
  - {{ . | title }}
  {{- end }}

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

audit:
  reserved: false
  users:
  - "audit"
  - "audit2"
