_meta:
  type: "roles"
  config_version: 2

# Restrict users so they can only view visualization and dashboard on OpenSearchDashboards
kibana_read_only:
  reserved: true

# The security REST API access role is used to assign specific users access to change the security settings through the REST API.
security_rest_api_access:
  reserved: true

anonymous_health_role:
  cluster_permissions:
    - cluster:monitor/health

data:
  reserved: false
  cluster_permissions:
  - "cluster_monitor"
  - "cluster_composite_ops"
  - "cluster:admin/ingest/pipeline/put"
  - "cluster:admin/ingest/pipeline/get"
  - "indices:admin/template/get"
  - "cluster_manage_index_templates"
  - "cluster:admin/opensearch/ml/predict"
  index_permissions:
  - index_patterns:
    - "deployments-datastream"
    - "alerts-datastream"
    - "logs-datastream"
    - "logs-swift-datastream"
    - "compute-datastream"
    - "storage-datastream"
    - "alerts-datastream"
    - "deployments-datastream"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/index"
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
    - "indices:data/write/index"
storage:
  reserved: false
  cluster_permissions:
  - "cluster_monitor"
  - "cluster_composite_ops"
  - "cluster:admin/ingest/pipeline/put"
  - "cluster:admin/ingest/pipeline/get"
  - "indices:admin/template/get"
  - "cluster_manage_index_templates"
  - "cluster:admin/opensearch/ml/predict"
  index_permissions:
  - index_patterns:
    - "storage-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/index"
compute:
  reserved: false
  cluster_permissions:
  - "cluster_monitor"
  - "cluster_composite_ops"
  - "cluster:admin/ingest/pipeline/put"
  - "cluster:admin/ingest/pipeline/get"
  - "indices:admin/template/get"
  - "cluster_manage_index_templates"
  - "cluster:admin/opensearch/ml/predict"
  index_permissions:
  - index_patterns:
    - "compute-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/index"
audit:
  reserved: false
  cluster_permissions:
  - "cluster_monitor"
  - "cluster_composite_ops"
  - "cluster:admin/ingest/pipeline/put"
  - "cluster:admin/ingest/pipeline/get"
  - "indices:admin/template/get"
  - "cluster_manage_index_templates"
  - "cluster:admin/opensearch/ml/predict"
  index_permissions:
  - index_patterns:
    - "audit-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/index"
otel:
  reserved: false
  cluster_permissions:
  - "cluster_monitor"
  - "cluster_composite_ops"
  - "cluster:admin/ingest/pipeline/put"
  - "cluster:admin/ingest/pipeline/get"
  - "indices:admin/template/get"
  - "cluster_manage_index_templates"
  - "cluster:admin/opensearch/ml/predict"
  index_permissions:
  - index_patterns:
    - "otel-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/index"
otellogs:
  reserved: false
  cluster_permissions:
  - "cluster_monitor"
  - "cluster_composite_ops"
  - "cluster:admin/ingest/pipeline/put"
  - "cluster:admin/ingest/pipeline/get"
  - "indices:admin/template/get"
  - "cluster_manage_index_templates"
  - "cluster:admin/opensearch/ml/predict"
  index_permissions:
  - index_patterns:
    - "otellogs-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/index"
otelstorage:
  reserved: false
  cluster_permissions:
  - "cluster_monitor"
  - "cluster_composite_ops"
  - "cluster:admin/ingest/pipeline/put"
  - "cluster:admin/ingest/pipeline/get"
  - "indices:admin/template/get"
  - "cluster_manage_index_templates"
  - "cluster:admin/opensearch/ml/predict"
  index_permissions:
  - index_patterns:
    - "otelstorage-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/index"
awx:
  reserved: false
  cluster_permissions:
  - "indices:admin/template/get"
  - "cluster_manage_index_templates"
  - "cluster:admin/ingest/pipeline/put"
  - "cluster:admin/ingest/pipeline/get"
  - "cluster:monitor/main"
  - "cluster:monitor/health"
  - "cluster:monitor/state"
  - "indices:data/read/scroll*"
  - "indices:data/read/msearch"
  - "indices:monitor/settings/get"
  - "indices:data/write/bulk"
  - "cluster_monitor"
  - "cluster_composite_ops"
  index_permissions:
  - index_patterns:
    - "awx-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mappings/get"
    - "indices:admin/mapping/put"
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
jaeger:
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
    - "jaeger-service-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/index"
  - index_patterns:
    - "jaeger-span-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/index"


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
  - "cluster:admin/opensearch/ql/datasources/read"
  - "cluster:monitor/task/get"
  - 'cluster:admin/opendistro/reports/definition/create'
  - 'cluster:admin/opendistro/reports/definition/update'
  - 'cluster:admin/opendistro/reports/definition/on_demand'
  - 'cluster:admin/opendistro/reports/definition/delete'
  - 'cluster:admin/opendistro/reports/definition/get'
  - 'cluster:admin/opendistro/reports/definition/list'
  - 'cluster:admin/opendistro/reports/instance/list'
  - 'cluster:admin/opendistro/reports/instance/get'
  - 'cluster:admin/opendistro/reports/menu/download'
  - 'cluster:admin/opensearch/ppl'
  index_permissions:
  - index_patterns:
    - "*"
    allowed_actions:
    - "search"
    - "read"
    - "get"
    - "indices:monitor/settings/get"
    - "indices:admin/create"
    - 'indices:admin/mappings/get'
    - 'indices:data/read/search*'
    - "indices:admin/get"
  tenant_permissions:
  - tenant_patterns:
    - "*"
    allowed_actions:
    - "kibana_all_write"
    - "kibana_all_read"

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

oraboskvmrole:
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

maillog:
  reserved: false
  cluster_permissions:
  - "indices:admin/template/get"
  - "cluster_manage_index_templates"
  - "cluster:monitor/main"
  - "cluster:monitor/health"
  - "cluster:monitor/state"
  - "indices:data/read/scroll*"
  - "indices:data/read/msearch"
  - "indices:monitor/settings/get"
  - "indices:data/write/bulk"
  index_permissions:
  - index_patterns:
    - "maillog-*"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mappings/get"
    - "indices:admin/mapping/put"
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
    - "logs-*"
    allowed_actions:
    - "read"
    - "indices:data/read/search*"
    - "indices:data/read/get"
    - "indices:monitor/settings/get"
    - "indices:monitor/stats"

jupyterhub:
  reserved: false
  hidden: false
  cluster_permissions:
    - "cluster:monitor/prometheus/metrics"
    - "cluster:monitor/health"
    - "cluster:monitor/main"
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

mlrole:
  reserved: false
  hidden: false
  cluster_permissions:
    - "cluster:monitor/prometheus/metrics"
  index_permissions:
  - index_patterns:
    - "*"
    allowed_actions:
    - "indices:admin/mappings/get"
    - "cluster:admin/opensearch/ql/datasources/*"

ml_full_access:
  reserved: true
  cluster_permissions:
    - "cluster:admin/opensearch/ml/*"
    - "cluster_monitor"
    - "cluster:admin/opensearch/mlinternal/*"
    - "cluster:admin/ingest/*"
  index_permissions:
    - index_patterns:
        - "*"
      allowed_actions:
        - "indices_monitor"
