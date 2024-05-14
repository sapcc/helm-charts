_meta:
  type: "roles"
  config_version: 2

# Restrict users so they can only view visualization and dashboard on OpenSearchDashboards
kibana_read_only:
  reserved: true

# The security REST API access role is used to assign specific users access to change the security settings through the REST API.
security_rest_api_access:
  reserved: true

adminrole:
  reserved: false
  hidden: false
  cluster_permissions:
  - "*"
  index_permissions:
  - index_patterns:
    - "*"
    allowed_actions:
    - "*"
  tenant_permissions:
  - tenant_patterns:
    - "global_tenant"
    allowed_actions:
    - "kibana_all_write"

complex-role:
  reserved: false
  hidden: false
  cluster_permissions:
  - "read"
  - "cluster:monitor/nodes/stats"
  - "cluster:monitor/task/get"
  # add permissions matching 'reports_read_access' role
  - 'cluster:admin/opendistro/reports/definition/get'
  - 'cluster:admin/opendistro/reports/definition/list'
  - 'cluster:admin/opendistro/reports/instance/get'
  - 'cluster:admin/opendistro/reports/instance/list'
  - 'cluster:admin/opendistro/reports/menu/download'
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

promrole:
  reserved: false
  hidden: false
  cluster_permissions:
    - "cluster:monitor/prometheus/metrics"
    - "cluster:monitor/health"
    - "cluster:monitor/state"
    - "cluster:monitor/nodes/info"
    - "cluster:monitor/nodes/stats"
    - "indices:data/read/scroll*"
    - "indices:data/read/msearch"
  index_permissions:
  - index_patterns:
    - "*"
    allowed_actions:
    - "indices:monitor/stats"
    - "indices:admin/mappings/get"
    - "indices:admin/aliases/get"
    - "indices:data/read/scroll"
    - "indices:data/read/scroll/clear"
    - "indices:data/read/search"
    - "indices:data/read/search*"
    - "read"
  tenant_permissions:
  - tenant_patterns:
    - "*"
    allowed_actions:
    - "kibana_all_write"

audit:
  reserved: false
  cluster_permissions:
  - "indices:admin/template/get"
  - "cluster_manage_index_templates"
  - "cluster:monitor/main"
  - "cluster:monitor/health"
  - "cluster:monitor/state"
  - "indices:monitor/settings/get"
  - "indices:data/read/scroll*"
  - "indices:data/read/msearch"
  - "indices:monitor/settings/get"
  - "indices:data/write/bulk"
  index_permissions:
  - index_patterns:
    - "audit-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mappings/get"
    - "indices:admin/mapping/put"
    - "indices:admin/refresh*"
    - "indices:admin/delete"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/delete/byquery"
    - "indices:data/write/index"
    - "indices:data/write/reindex"
    - "indices:data/write/update"
    - "indices:data/write/update/byquery"
    - "read"
    - "indices:monitor/settings/get"
    - "indices:monitor/stats"
  - index_patterns:
    - "*"
    allowed_actions:
    - "indices:monitor/settings/get"
    - "indices:monitor/stats"
