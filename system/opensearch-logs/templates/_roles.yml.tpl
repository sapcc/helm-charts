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
  reserved: false
  cluster_permissions:
  - "cluster_monitor"
  - "cluster_composite_ops"
  - "cluster:admin/ingest/pipeline/put"
  - "cluster:admin/ingest/pipeline/get"
  - "indices:admin/template/get"
  - "cluster_manage_index_templates"
  index_permissions:
  - index_patterns:
    - "logstash-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/index"
    - "indices:data/write/update"
  - index_patterns:
    - "systemd-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/index"
    - "indices:data/write/update"
  - index_patterns:
    - "kubernikus-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/index"
    - "indices:data/write/update"
  - index_patterns:
    - "scaleout-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/index"
    - "indices:data/write/update"
  - index_patterns:
    - "virtual-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/index"
    - "indices:data/write/update"
  - index_patterns:
    - "admin-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/index"
    - "indices:data/write/update"

syslog:
  reserved: false
  cluster_permissions:
  - "cluster_monitor"
  - "cluster_composite_ops"
  - "cluster:admin/ingest/pipeline/put"
  - "cluster:admin/ingest/pipeline/get"
  - "indices:admin/template/get"
  - "cluster_composite_ops"
  - "cluster_manage_index_templates"
  index_permissions:
  - index_patterns:
    - "syslog-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/index"
    - "indices:data/write/update"
  - index_patterns:
    - "alerts-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/index"
    - "indices:data/write/update"
  - index_patterns:
    - "deployments-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/index"
    - "indices:data/write/update"
  - index_patterns:
    - "nsxt-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/index"
    - "indices:data/write/update"
  - index_patterns:
    - "netflow-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/index"
    - "indices:data/write/update"

jump:
  reserved: false
  cluster_permissions:
  - "cluster_monitor"
  - "cluster_composite_ops"
  - "cluster:admin/ingest/pipeline/put"
  - "cluster:admin/ingest/pipeline/get"
  - "indices:admin/template/get"
  - "cluster_composite_ops"
  - "cluster_manage_index_templates"
  index_permissions:
  - index_patterns:
    - "jump-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/index"
    - "indices:data/write/update"

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
