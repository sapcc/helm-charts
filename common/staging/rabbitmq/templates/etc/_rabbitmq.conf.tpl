
management.load_definitions = /etc/rabbitmq/definitions.json

hipe_compile = {{ .Values.hipe_compile }}
vm_memory_high_watermark.relative = 0.6
disk_free_limit.absolute = 1G
log.console = true
log.federation.level = debug

## Clustering
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_k8s
cluster_formation.k8s.host = kubernetes.default.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
cluster_formation.k8s.address_type = hostname
cluster_formation.k8s.hostname_suffix = .{{ template "rabbitmq.release_host" . }}
cluster_formation.randomized_startup_delay_range.min = 0
cluster_formation.randomized_startup_delay_range.max = 2

# Set to false if automatic removal of unknown/absent nodes
# is desired. This can be dangerous, see
#  * http://www.rabbitmq.com/cluster-formation.html#node-health-checks-and-cleanup
#  * https://groups.google.com/forum/#!msg/rabbitmq-users/wuOfzEywHXo/k8z_HWIkBgAJ
cluster_formation.node_cleanup.only_log_warning = true
cluster_partition_handling = autoheal

## queue master locator 
queue_master_locator = min-masters
