[DEFAULT]
{{ include "swift_log_statsd" . }}
{{ if .Values.debug -}}
log_level = DEBUG
{{- else -}}
log_level = INFO
{{- end }}

[container-reconciler]
# The reconciler will re-attempt reconciliation if the source object is not
# available up to reclaim_age seconds before it gives up and deletes the entry
# in the queue.
# reclaim_age = 604800
# The cycle time of the daemon
# interval = 300
# Server errors from requests will be retried by default
# request_tries = 3

[pipeline:main]
# TODO: Reenable cache when container-reconciler does not run as privileged container anymore,
# because the k8s internal svc cannot be resolved for privileged containers
#pipeline = catch_errors proxy-logging cache proxy-server
pipeline = catch_errors proxy-logging proxy-server

[app:proxy-server]
use = egg:swift#proxy
# See proxy-server.conf-sample for options

[filter:cache]
use = egg:swift#memcache
memcache_servers = memcached.{{.Release.Namespace}}.svc:11211
# See proxy-server.conf-sample for options

[filter:proxy-logging]
use = egg:swift#proxy_logging

[filter:catch_errors]
use = egg:swift#catch_errors
# See proxy-server.conf-sample for options
