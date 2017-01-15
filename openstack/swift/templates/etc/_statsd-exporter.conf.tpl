{{/* The file format itself does not support comments, so I use golang text/template comments here. */}}
{{/* Reference for statsd metric names emitted by Swift: */}}
{{/* <http://docs.openstack.org/developer/swift/admin_guide.html#reporting-metrics-to-statsd> */}}
{{/* Reference for this file's format: */}}
{{/* <https://github.com/prometheus/statsd_exporter#metric-mapping-and-configuration> */}}

{{/* #################### proxy metrics coming from the proxy-logging middleware #################### */}}

swift.proxy-server.*.policy.*.*.*.timing
name="swift_proxy"
type="$1"
policy="$2"
method="$3"
status="$4"

swift.proxy-server.*.policy.*.GET.*.first-byte.timing
name="swift_proxy_firstbyte"
type="$1"
policy="$2"
status="$3"

swift.proxy-server.*.policy.*.*.*.xfer
name="swift_proxy_transfer"
type="$1"
policy="$2"
method="$3"
status="$4"

swift.proxy-server.*.*.*.timing
name="swift_proxy"
type="$1"
policy="all"
method="$2"
status="$3"

swift.proxy-server.*.GET.*.first-byte.timing
name="swift_proxy_firstbyte"
type="$1"
policy="all"
status="$2"

swift.proxy-server.*.*.*.xfer
name="swift_proxy_transfer"
type="$1"
policy="all"
method="$2"
status="$3"

{{/* #################### storage server timing metrics #################### */}}

swift.account-server.*.timing
name="swift_storage_server"
type="account"
method="$1"
status="ok"

swift.account-server.*.errors.timing
name="swift_storage_server"
type="account"
method="$1"
status="error"

swift.container-server.*.timing
name="swift_storage_server"
type="container"
method="$1"
status="ok"

swift.container-server.*.errors.timing
name="swift_storage_server"
type="container"
method="$1"
status="error"

swift.object-server.*.timing
name="swift_storage_server"
type="object"
method="$1"
status="ok"

swift.object-server.*.errors.timing
name="swift_storage_server"
type="object"
method="$1"
status="error"

swift.object-server.*.*.timing
name="swift_storage_server_by_device"
type="object"
method="$1"
status="ok"
device="$2"

{{/* #################### background service metrics #################### */}}

swift.object-replicator.partition.*.count.*
name="swift_object_replicator_partition"
action="$1" {{/* "update" or "delete" */}}
device="$2"

swift.object-replicator.partition.*.timing
name="swift_object_replicator"
action="$1"

{{/* #################### remove superfluous "timing" word from timer names #################### */}}

swift.account-auditor.timing
name="swift_account_auditor"

swift.account-replicator.timing
name="swift_account_replicator"

swift.container-auditor.timing
name="swift_container_auditor"

swift.container-replicator.timing
name="swift_container_replicator"

swift.container-updater.timing
name="swift_container_updater"

swift.object-auditor.timing
name="swift_object_auditor"

swift.object-expirer.timing
name="swift_object_expirer"

swift.object-replicator.timing
name="swift_object_replicator"

swift.object-updater.timing
name="swift_object_updater"

{{/* #################### extract storage IP from swift-recon metrics (sent by swift-health-statsd) #################### */}}
{{/* #################### This is unnecessarily verbose because it won't let me write name="swift_cluster_$1". #################### */}}

swift_cluster.accounts_quarantined.from.*.*.*.*
name="swift_cluster_accounts_quarantined"
storage_ip="$1.$2.$3.$4"

swift_cluster.accounts_replication_age.from.*.*.*.*
name="swift_cluster_accounts_replication_age"
storage_ip="$1.$2.$3.$4"

swift_cluster.accounts_replication_duration.from.*.*.*.*
name="swift_cluster_accounts_replication_duration"
storage_ip="$1.$2.$3.$4"

swift_cluster.containers_quarantined.from.*.*.*.*
name="swift_cluster_containers_quarantined"
storage_ip="$1.$2.$3.$4"

swift_cluster.containers_replication_age.from.*.*.*.*
name="swift_cluster_containers_replication_age"
storage_ip="$1.$2.$3.$4"

swift_cluster.containers_replication_duration.from.*.*.*.*
name="swift_cluster_containers_replication_duration"
storage_ip="$1.$2.$3.$4"

swift_cluster.containers_updater_sweep_time.from.*.*.*.*
name="swift_cluster_containers_updater_sweep_time"
storage_ip="$1.$2.$3.$4"

swift_cluster.drives_audit_errors.from.*.*.*.*
name="swift_cluster_drives_audit_errors"
storage_ip="$1.$2.$3.$4"

swift_cluster.drives_unmounted.from.*.*.*.*
name="swift_cluster_drives_unmounted"
storage_ip="$1.$2.$3.$4"

swift_cluster.objects_quarantined.from.*.*.*.*
name="swift_cluster_objects_quarantined"
storage_ip="$1.$2.$3.$4"

swift_cluster.objects_replication_age.from.*.*.*.*
name="swift_cluster_objects_replication_age"
storage_ip="$1.$2.$3.$4"

swift_cluster.objects_replication_duration.from.*.*.*.*
name="swift_cluster_objects_replication_duration"
storage_ip="$1.$2.$3.$4"

swift_cluster.objects_updater_sweep_time.from.*.*.*.*
name="swift_cluster_objects_updater_sweep_time"
storage_ip="$1.$2.$3.$4"

swift_cluster.storage_used_percent.disk.*.from.*.*.*.*
name="swift_cluster_storage_used_percent_by_disk"
disk="$1"
storage_ip="$2.$3.$4.$5"
