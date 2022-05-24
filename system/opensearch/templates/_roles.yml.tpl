_meta:
  type: "roles"
  config_version: 2

# Restrict users so they can only view visualization and dashboard on OpenSearchDashboards
kibana_read_only:
  reserved: true

# The security REST API access role is used to assign specific users access to change the security settings through the REST API.
security_rest_api_access:
  reserved: true


data:
  reserved: true
  index_permissions:
  - index_patterns:
    - "logstash-*"
    allowed_actions:
    - "indices:admin/types/exists"
    - "indices:data/read/*"
    - "indices:data/write/*"
    - "indices:admin/template/*"
    - "indices:admin/create"
    - "cluster:monitor/*"
  - index_patterns:
    - "netflow-*"
    allowed_actions:
    - "indices:admin/types/exists"
    - "indices:data/read/*"
    - "indices:data/write/*"
    - "indices:admin/template/*"
    - "indices:admin/create"
    - "cluster:monitor/*"
  - index_patterns:
    - "systemd-*"
    allowed_actions:
    - "indices:admin/types/exists"
    - "indices:data/read/*"
    - "indices:data/write/*"
    - "indices:admin/template/*"
    - "indices:admin/create"
    - "cluster:monitor/*"
  - index_patterns:
    - "syslog-*"
    allowed_actions:
    - "indices:admin/types/exists"
    - "indices:data/read/*"
    - "indices:data/write/*"
    - "indices:admin/template/*"
    - "indices:admin/create"
    - "cluster:monitor/*"
  - index_patterns:
    - "scaleout-*"
    allowed_actions:
    - "indices:admin/types/exists"
    - "indices:data/read/*"
    - "indices:data/write/*"
    - "indices:admin/template/*"
    - "indices:admin/create"
    - "cluster:monitor/*"
  - index_patterns:
    - "virtual-*"
    allowed_actions:
    - "indices:admin/types/exists"
    - "indices:data/read/*"
    - "indices:data/write/*"
    - "indices:admin/template/*"
    - "indices:admin/create"
    - "cluster:monitor/*"
  - index_patterns:
    - "alerts-*"
    allowed_actions:
    - "indices:admin/types/exists"
    - "indices:data/read/*"
    - "indices:data/write/*"
    - "indices:admin/template/*"
    - "indices:admin/create"
    - "cluster:monitor/*"
  - index_patterns:
    - "deployments-*"
    allowed_actions:
    - "indices:admin/types/exists"
    - "indices:data/read/*"
    - "indices:data/write/*"
    - "indices:admin/template/*"
    - "indices:admin/create"
    - "cluster:monitor/*"
  - index_patterns:
    - "nsxt-*"
    allowed_actions:
    - "indices:admin/types/exists"
    - "indices:data/read/*"
    - "indices:data/write/*"
    - "indices:admin/template/*"
    - "indices:admin/create"
    - "cluster:monitor/*"

adminrole:
  reserved: false
  hidden: false
  cluster_permissions:
  - "cluster:*"
  index_permissions:
  - index_patterns:
    - "*"
    allowed_actions:
    - "*"

complex-role:
  reserved: false
  hidden: false
  cluster_permissions:
  - "read"
  - "cluster:monitor/nodes/stats"
  - "cluster:monitor/task/get"
  index_permissions:
  - index_patterns:
    - "*"
    allowed_actions:
    - "read"
  tenant_permissions:
  - tenant_patterns:
    - "*"
    allowed_actions:
    - "kibana_all_write"
