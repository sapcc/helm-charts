load_definitions = /etc/rabbitmq/definitions.json

vm_memory_high_watermark.relative = 0.6
{{- if .Values.resources.limits.memory }}
vm_memory_high_watermark.absolute = {{ .Values.resources.limits.memory }}
{{- end }}
disk_free_limit.absolute = 1G
log.console = true
log.federation.level = debug
ssl_options = none

{{- if .Values.cluster.enabled }}
## Clustering
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_k8s
cluster_formation.k8s.host = kubernetes.default.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}
cluster_formation.k8s.address_type = hostname
cluster_formation.k8s.hostname_suffix = .{{ template "rabbitmq.release_host" . }}

# Set to false if automatic removal of unknown/absent nodes
# is desired. This can be dangerous, see
#  * http://www.rabbitmq.com/cluster-formation.html#node-health-checks-and-cleanup
#  * https://groups.google.com/forum/#!msg/rabbitmq-users/wuOfzEywHXo/k8z_HWIkBgAJ
cluster_formation.node_cleanup.only_log_warning = true
cluster_partition_handling = autoheal

## queue master locator 
queue_master_locator = min-masters
{{- end }}