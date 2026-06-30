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
    - "cronus-datastream"
    - "traces-datastream"
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
  - "cluster:admin/opendistro/reports/definition/create"
  - "cluster:admin/opendistro/reports/definition/update"
  - "cluster:admin/opendistro/reports/definition/on_demand"
  - "cluster:admin/opendistro/reports/definition/delete"
  - "cluster:admin/opendistro/reports/definition/get"
  - "cluster:admin/opendistro/reports/definition/list"
  - "cluster:admin/opendistro/reports/instance/list"
  - "cluster:admin/opendistro/reports/instance/get"
  - "cluster:admin/opendistro/reports/menu/download"
  - "cluster:admin/opensearch/ppl"
  index_permissions:
  - index_patterns:
    - "logs-datastream"
    - "storage-datastream"
    - "logs-swift-datastream"
    - "jump-datastream"
    - "deployments-datastream"
    - "cronus-datastream"
    - "alerts-sem-datastream"
    - "awx-api"
    - "alerts-datastream"
    - "maillog-*"
    allowed_actions:
    - "search"
    - "read"
    - "get"
    - "indices:monitor/settings/get"
    - "indices:admin/create"
    - "indices:admin/mappings/get"
    - "indices:data/read/search*"
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
    - "logs-datastream"
    - "storage-datastream"
    - "logs-swift-datastream"
    - "jump-datastream"
    - "deployments-datastream"
    - "cronus-datastream"
    - "alerts-sem-datastream"
    - "alerts-datastream"
    - "maillog-*"
    - "remote_.ds-logs-datastream*"
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

auditorrole:
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
  - "cluster_monitor"
  - "cluster_composite_ops"
  - "cluster:admin/ingest/pipeline/put"
  - "cluster:admin/ingest/pipeline/get"
  - "indices:admin/template/get"
  - "cluster_manage_index_templates"
  - "cluster:admin/opensearch/ml/predict"
  index_permissions:
  - index_patterns:
    - "alerts-sem-datastream"
    allowed_actions:
    - "indices:admin/template/get"
    - "indices:admin/template/put"
    - "indices:admin/mapping/put"
    - "indices:admin/create"
    - "indices:data/write/bulk*"
    - "indices:data/write/index"
  - index_patterns:
    - "*"
    allowed_actions:
    - "indices:monitor/stats"
    - "indices:admin/mappings/get"
    - "indices:admin/aliases/get"
    - "indices:data/read/scroll"
    - "indices:data/read/scroll/clear"
    - "indices:data/read/search*"
    - "read"
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

security_analytics_full_access:
  reserved: true
  cluster_permissions:
  - "cluster:admin/opensearch/securityanalytics/alerts/*"
  - "cluster:admin/opensearch/securityanalytics/connections/*"
  - "cluster:admin/opensearch/securityanalytics/correlationAlerts/*"
  - "cluster:admin/opensearch/securityanalytics/correlations/*"
  - "cluster:admin/opensearch/securityanalytics/detector/*"
  - "cluster:admin/opensearch/securityanalytics/findings/*"
  - "cluster:admin/opensearch/securityanalytics/logtype/*"
  - "cluster:admin/opensearch/securityanalytics/mapping/*"
  - "cluster:admin/opensearch/securityanalytics/rule/*"
  - "cluster:admin/opensearch/securityanalytics/threatintel/*"
  - "cluster:monitor/tasks/lists"                        # SA detector async task status checks
  - "indices:admin/index_template/put"                   # Terraform creates/updates composable templates (cluster-level only)
  - "indices:admin/index_template/delete"                # Terraform destroys composable templates (cluster-level only)
  - "indices:monitor/settings/get"                       # Terraform provider GET /<index>/_settings (cluster-level scope)
  index_permissions:
  - index_patterns:
    - "*"
    allowed_actions:
    - "indices:admin/get"               # Terraform existence checks before create; index name unknown at check time
    - "indices:admin/aliases/get"       # Terraform GET /_aliases with no index filter
    - "indices:admin/resolve/index"     # Wildcard resolve calls by Terraform and SA plugin
    - "indices:admin/data_stream/get"   # SA inspects data streams by wildcard; read-only
    - "indices:admin/mapping/put"       # base role
    - "indices:admin/mappings/get"      # base role
  - index_patterns:
    - ".opensearch-sap-*"
    allowed_actions:
    - "system:admin/system_index"        # defensive: required when system_indices.enabled=true
    - "indices:admin/create"
    - "indices:admin/delete"             # SA recreates query indices 
    - "indices:admin/aliases"
    - "indices:admin/mapping/put"
    - "indices:admin/mappings/get"
    - "indices:data/read/search"
    - "indices:data/read/get"
    - "indices:data/read/field_caps"
    - "indices:data/write/index"
    - "indices:data/write/bulk"          # bulk API — must be granted at index level per OpenSearch docs
    - "indices:data/write/bulk*"         # bulk API wildcard — DocLevelMonitorQueries writes to .opensearch-alerting-queries-*
    - "indices:data/write/delete/byquery"
    - "indices:monitor/stats"
    - "indices:monitor/settings/get"
    - "indices:monitor/recovery"
  - index_patterns:
    - "audit-ds*"
    allowed_actions:
    - "indices:admin/mappings/get"       # SA reads field mappings for detector mapping
    - "indices:data/read/search"
    - "indices:data/read/get"
    - "indices:data/read/field_caps"
    - "indices:monitor/settings/get"
  - index_patterns:
    - "sci-cyber-security-alerts-*"
    - "sci-cyber-defense-alerts-*"
    - "sci-cyber-defense-findings-*"
    allowed_actions:
    - "indices:admin/create"
    - "indices:admin/delete"
    - "indices:admin/aliases"
    - "indices:admin/mapping/put"
    - "indices:admin/mappings/get"
    - "indices:data/read/get"
    - "indices:data/read/search"
    - "indices:monitor/settings/get"
    - "indices:monitor/recovery"

alerting_full_access:
  reserved: true
  cluster_permissions:
  - "cluster:admin/opendistro/alerting/alerts/ack"
  - "cluster:admin/opendistro/alerting/alerts/get"
  - "cluster:admin/opendistro/alerting/destination/delete"
  - "cluster:admin/opendistro/alerting/destination/email_account/delete"
  - "cluster:admin/opendistro/alerting/destination/email_account/get"
  - "cluster:admin/opendistro/alerting/destination/email_account/search"
  - "cluster:admin/opendistro/alerting/destination/email_account/write"
  - "cluster:admin/opendistro/alerting/destination/email_group/delete"
  - "cluster:admin/opendistro/alerting/destination/email_group/get"
  - "cluster:admin/opendistro/alerting/destination/email_group/search"
  - "cluster:admin/opendistro/alerting/destination/email_group/write"
  - "cluster:admin/opendistro/alerting/destination/get"
  - "cluster:admin/opendistro/alerting/destination/write"
  - "cluster:admin/opendistro/alerting/monitor/delete"
  - "cluster:admin/opendistro/alerting/monitor/execute"
  - "cluster:admin/opendistro/alerting/monitor/get"
  - "cluster:admin/opendistro/alerting/monitor/search"
  - "cluster:admin/opendistro/alerting/monitor/write"
  - "cluster:admin/opensearch/alerting/remote/indexes/get"
  - "cluster:admin/opensearch/notifications/*"
  - "indices:data/write/bulk"   # bulk API — required at cluster level for DocLevelMonitorQueries
  - "indices:data/write/bulk*"  # bulk API wildcard — required at cluster level per OpenSearch docs
  index_permissions:
  - index_patterns:
    - ".opendistro-alerting-config"
    - ".opensearch-alerting-config*"
    - ".opensearch-alerting-alerts*"
    - ".opensearch-alerting-finding*"
    - ".opensearch-alerting-queries*"
    - ".opensearch-alerting-comments*"
    - ".opensearch-alerting-config-lock"
    allowed_actions:
    - "system:admin/system_index"
    - "indices:admin/create"
    - "indices:admin/delete"
    - "indices:admin/get"
    - "indices:admin/aliases"
    - "indices:admin/aliases/get"
    - "indices:admin/mapping/put"
    - "indices:admin/mappings/get"
    - "indices:admin/resolve/index"
    - "indices:data/read/search"
    - "indices:data/read/get"
    - "indices:data/write/index"
    - "indices:data/write/bulk"
    - "indices:data/write/bulk*"
    - "indices:data/write/delete"
    - "indices:data/write/delete/byquery"
    - "indices:monitor/settings/get"
    - "indices:monitor/stats"

siem_terraform_operator:
  reserved: false
  cluster_permissions:
  - "cluster:admin/opendistro/ism/policy/search"        # Terraform reads ISM policies
  - "cluster:admin/opendistro/ism/managedindex/explain" # Terraform calls GET /_plugins/_ism/explain/<index>
  - "cluster:monitor/main"                              # Terraform provider health check (GET /)
  - "cluster:monitor/health"                            # GET /_cluster/health — Terraform and bootstrap scripts
  - "indices:admin/index_template/get"                  # Terraform reads composable templates (cluster-level only)
  - "cluster:monitor/remote/info"                       # Remote cluster info — retained for future CCS use
  index_permissions:
  - index_patterns:
    - ".kibana*"
    - ".opensearch_dashboards*"
    allowed_actions:
    - "system:admin/system_index"        # .kibana* is a system index; required when system_indices.enabled=true
    - "indices:data/write/index"
    - "indices:data/write/delete"
    - "indices:data/read/get"
    - "indices:data/read/search"          # Dashboards saved-objects GET checks for existing objects
    - "indices:data/write/bulk"
    - "indices:data/write/bulk*"          # covers shard-level dispatch bulk[s]
    - "indices:data/write/update"         # Dashboards saved-objects PATCH/update path
    - "indices:admin/get"
    - "indices:admin/create"
    - "indices:admin/mappings/get"        # Provider reads mappings before writing saved objects
  tenant_permissions:
  - tenant_patterns:
    - "global_tenant"
    allowed_actions:
    - "kibana_all_write"                  # Required by Dashboards saved-objects API for index-pattern create/update
