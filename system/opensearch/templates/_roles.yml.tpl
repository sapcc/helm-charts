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
        - 'logstash-*'
        - 'netflow-*'
        - 'systemd-*'
        - 'syslog-*'
        - 'scaleout-*'
        - 'virtual-*'
        - 'alerts-*'
        - 'deployments-*'
        - 'nsxt-*'
      allowed_actions:
        - 'indices:admin/types/exists'
        - 'indices:data/read/*'
        - 'indices:data/write/*'
        - 'indices:admin/template/*'
        - 'indices:admin/create'
        - 'cluster:monitor/*'

{{- if .Values.qalogs.enabled }}
dataqade2:
  reserved: true
  index_permissions:
    - index_patterns:
        - 'qade2-logstash-*'
      allowed_actions:
        - 'indices:admin/types/exists'
        - 'indices:data/read/*'
        - 'indices:data/write/*'
        - 'indices:admin/template/*'
        - 'indices:admin/create'
        - 'cluster:monitor/*'

dataqade3:
  reserved: true
  index_permissions:
    - index_patterns:
        - 'qade3-logstash-*'
      allowed_actions:
        - 'indices:admin/types/exists'
        - 'indices:data/read/*'
        - 'indices:data/write/*'
        - 'indices:admin/template/*'
        - 'indices:admin/create'
        - 'cluster:monitor/*'

dataqade5:
  reserved: true
  index_permissions:
    - index_patterns:
        - 'qade5-logstash-*'
      allowed_actions:
        - 'indices:admin/types/exists'
        - 'indices:data/read/*'
        - 'indices:data/write/*'
        - 'indices:admin/template/*'
        - 'indices:admin/create'
        - 'cluster:monitor/*'
{{- end }}

jump:
  reserved: true
  index_permissions:
    - index_patterns:
        - 'jump-*'
      allowed_actions:
        - 'indices:admin/types/exists'
        - 'indices:data/read/*'
        - 'indices:data/write/*'
        - 'indices:admin/template/*'
        - 'indices:admin/create'
        - 'cluster:monitor/*'

jaeger:
  reserved: true
  index_permissions:
    - index_patterns:
        - 'jaeger-*'
      allowed_actions:
        - 'indices:admin/types/exists'
        - 'indices:data/read/*'
        - 'indices:data/write/*'
        - 'indices:admin/template/*'
        - 'indices:admin/create'
        - 'cluster:monitor/*'

winbeat:
  reserved: true
  index_permissions:
    - index_patterns:
        - 'winbeat-*'
      allowed_actions:
        - 'indices:admin/types/exists'
        - 'indices:data/read/*'
        - 'indices:data/write/*'
        - 'indices:admin/template/*'
        - 'indices:admin/create'
        - 'cluster:monitor/*'

promuser:
  reserved: true
  index_permissions:
    - index_patterns:
        - 'logstash-*'
        - 'netflow-*'
        - 'systemd-*'
        - 'syslog-*'
        - 'scaleout-*'
        - 'virtual-*'
        - 'alerts-*'
        - 'deployments-*'
        - 'nsxt-*
      allowed_actions:
        - 'indices:data/read/*'
        - 'cluster:monitor/state'
        - 'indices:admin/get'
        - 'indices:admin/mappings/fields/get'
        - 'indices:admin/mappings/get'
        - 'indices:admin/aliases/get'
        - 'indices:admin/template/get'

adminrole:
  reserved: false
  hidden: false
  cluster_permissions:
    - 'cluster:*'

# Allows users to view monitors, destinations and alerts
alerting_read_access:
  reserved: true
  cluster_permissions:
    - 'cluster:admin/opendistro/alerting/alerts/get'
    - 'cluster:admin/opendistro/alerting/destination/get'
    - 'cluster:admin/opendistro/alerting/monitor/get'
    - 'cluster:admin/opendistro/alerting/monitor/search'

# Allows users to view and acknowledge alerts
alerting_ack_alerts:
  reserved: true
  cluster_permissions:
    - 'cluster:admin/opendistro/alerting/alerts/*'

# Allows users to use all alerting functionality
alerting_full_access:
  reserved: true
  cluster_permissions:
    - 'cluster_monitor'
    - 'cluster:admin/opendistro/alerting/*'
  index_permissions:
    - index_patterns:
        - '*'
      allowed_actions:
        - 'indices_monitor'
        - 'indices:admin/aliases/get'
        - 'indices:admin/mappings/get'

# Allow users to read Anomaly Detection detectors and results
anomaly_read_access:
  reserved: true
  cluster_permissions:
    - 'cluster:admin/opendistro/ad/detector/info'
    - 'cluster:admin/opendistro/ad/detector/search'
    - 'cluster:admin/opendistro/ad/detectors/get'
    - 'cluster:admin/opendistro/ad/result/search'
    - 'cluster:admin/opendistro/ad/tasks/search'
    - 'cluster:admin/opendistro/ad/detector/validate'
    - 'cluster:admin/opendistro/ad/result/topAnomalies'

# Allows users to use all Anomaly Detection functionality
anomaly_full_access:
  reserved: true
  cluster_permissions:
    - 'cluster_monitor'
    - 'cluster:admin/opendistro/ad/*'
  index_permissions:
    - index_patterns:
        - '*'
      allowed_actions:
        - 'indices_monitor'
        - 'indices:admin/aliases/get'
        - 'indices:admin/mappings/get'

# Allows users to read Notebooks
notebooks_read_access:
  reserved: true
  cluster_permissions:
    - 'cluster:admin/opendistro/notebooks/list'
    - 'cluster:admin/opendistro/notebooks/get'

# Allows users to all Notebooks functionality
notebooks_full_access:
  reserved: true
  cluster_permissions:
    - 'cluster:admin/opendistro/notebooks/create'
    - 'cluster:admin/opendistro/notebooks/update'
    - 'cluster:admin/opendistro/notebooks/delete'
    - 'cluster:admin/opendistro/notebooks/get'
    - 'cluster:admin/opendistro/notebooks/list'

# Allows users to read observability objects
observability_read_access:
  reserved: true
  cluster_permissions:
    - 'cluster:admin/opensearch/observability/get'

# Allows users to all Observability functionality
observability_full_access:
  reserved: true
  cluster_permissions:
    - 'cluster:admin/opensearch/observability/create'
    - 'cluster:admin/opensearch/observability/update'
    - 'cluster:admin/opensearch/observability/delete'
    - 'cluster:admin/opensearch/observability/get'

# Allows users to read and download Reports
reports_instances_read_access:
  reserved: true
  cluster_permissions:
    - 'cluster:admin/opendistro/reports/instance/list'
    - 'cluster:admin/opendistro/reports/instance/get'
    - 'cluster:admin/opendistro/reports/menu/download'

# Allows users to read and download Reports and Report-definitions
reports_read_access:
  reserved: true
  cluster_permissions:
    - 'cluster:admin/opendistro/reports/definition/get'
    - 'cluster:admin/opendistro/reports/definition/list'
    - 'cluster:admin/opendistro/reports/instance/list'
    - 'cluster:admin/opendistro/reports/instance/get'
    - 'cluster:admin/opendistro/reports/menu/download'

# Allows users to all Reports functionality
reports_full_access:
  reserved: true
  cluster_permissions:
    - 'cluster:admin/opendistro/reports/definition/create'
    - 'cluster:admin/opendistro/reports/definition/update'
    - 'cluster:admin/opendistro/reports/definition/on_demand'
    - 'cluster:admin/opendistro/reports/definition/delete'
    - 'cluster:admin/opendistro/reports/definition/get'
    - 'cluster:admin/opendistro/reports/definition/list'
    - 'cluster:admin/opendistro/reports/instance/list'
    - 'cluster:admin/opendistro/reports/instance/get'
    - 'cluster:admin/opendistro/reports/menu/download'

# Allows users to use all asynchronous-search functionality
asynchronous_search_full_access:
  reserved: true
  cluster_permissions:
    - 'cluster:admin/opendistro/asynchronous_search/*'
  index_permissions:
    - index_patterns:
        - '*'
      allowed_actions:
        - 'indices:data/read/search*'

# Allows users to read stored asynchronous-search results
asynchronous_search_read_access:
  reserved: true
  cluster_permissions:
    - 'cluster:admin/opendistro/asynchronous_search/get'

# Allows user to use all index_management actions - ism policies, rollups, transforms
index_management_full_access:
  reserved: true
  cluster_permissions:
    - "cluster:admin/opendistro/ism/*"
    - "cluster:admin/opendistro/rollup/*"
    - "cluster:admin/opendistro/transform/*"
  index_permissions:
    - index_patterns:
        - '*'
      allowed_actions:
        - 'indices:admin/opensearch/ism/*'

# Allows users to use all cross cluster replication functionality at leader cluster
cross_cluster_replication_leader_full_access:
  reserved: true
  index_permissions:
    - index_patterns:
        - '*'
      allowed_actions:
        - "indices:admin/plugins/replication/index/setup/validate"
        - "indices:data/read/plugins/replication/changes"
        - "indices:data/read/plugins/replication/file_chunk"

# Allows users to use all cross cluster replication functionality at follower cluster
cross_cluster_replication_follower_full_access:
  reserved: true
  cluster_permissions:
    - "cluster:admin/plugins/replication/autofollow/update"
  index_permissions:
    - index_patterns:
        - '*'
      allowed_actions:
        - "indices:admin/plugins/replication/index/setup/validate"
        - "indices:data/write/plugins/replication/changes"
        - "indices:admin/plugins/replication/index/start"
        - "indices:admin/plugins/replication/index/pause"
        - "indices:admin/plugins/replication/index/resume"
        - "indices:admin/plugins/replication/index/stop"
        - "indices:admin/plugins/replication/index/update"
        - "indices:admin/plugins/replication/index/status_check"

# Allow users to read ML stats/models/tasks
ml_read_access:
  reserved: true
  cluster_permissions:
    - 'cluster:admin/opensearch/ml/stats/nodes'
    - 'cluster:admin/opensearch/ml/models/get'
    - 'cluster:admin/opensearch/ml/models/search'
    - 'cluster:admin/opensearch/ml/tasks/get'
    - 'cluster:admin/opensearch/ml/tasks/search'

# Allows users to use all ML functionality
ml_full_access:
  reserved: true
  cluster_permissions:
    - 'cluster_monitor'
    - 'cluster:admin/opensearch/ml/*'
  index_permissions:
    - index_patterns:
        - '*'
      allowed_actions:
        - 'indices_monitor'
