{{- define "log_router_image" -}}
  {{- if contains "DEFINED" $.Values.logRouter.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.global.registry}}/hermes-logrouter:{{$.Values.logRouter.image_tag}}
  {{- end -}}
{{- end -}}

{{- /* one amqp url per broker pod: (list $ "<alias>" <replicas> <port>) */ -}}
{{- define "log_router_rabbitmq_broker_urls" -}}
{{- $ := index . 0 -}}
{{- $alias := index . 1 -}}
{{- $replicas := int (index . 2) -}}
{{- $port := index . 3 -}}
{{- if le $replicas 0 -}}
  {{- fail (printf ".Values.%s.replicas must be greater than zero when logRouter.enabled=true" $alias) -}}
{{- end -}}
{{- $service := printf "%s-%s" $.Release.Name ($alias | replace "_" "-") -}}
{{- $domain := printf "%s.svc.%s" $.Release.Namespace (required ".Values.global.clusterDNSSearchDomain is missing" $.Values.global.clusterDNSSearchDomain) -}}
{{- $urls := list -}}
{{- range $i := until $replicas -}}
  {{- $host := printf "%s-%d.%s.%s" $service $i $service $domain -}}
  {{- $urls = append $urls (printf "amqp://$(RABBITMQ_USER):$(RABBITMQ_PASSWORD)@%s:%v/" $host $port) -}}
{{- end -}}
{{- join "," $urls -}}
{{- end -}}

{{- /*
  rabbitmq_dataplane off: read rabbitmq_notifications only.
  rabbitmq_dataplane on: read rabbitmq_dataplane, plus rabbitmq_notifications
  while logRouter.rabbitmq.also_read_notifications is true (cutover).
*/ -}}
{{- define "log_router_rabbitmq_urls" -}}
{{- $urls := list -}}
{{- $readNotifications := true -}}
{{- if $.Values.hermes.rabbitmq_dataplane_enabled -}}
  {{- $dp := $.Values.rabbitmq_dataplane -}}
  {{- $dpPort := 5672 -}}
  {{- with $dp.ports }}{{ $dpPort = default 5672 .public }}{{ end -}}
  {{- $urls = append $urls (include "log_router_rabbitmq_broker_urls" (list $ "rabbitmq_dataplane" (required ".Values.rabbitmq_dataplane.replicas is missing" $dp.replicas) $dpPort)) -}}
  {{- $readNotifications = $.Values.logRouter.rabbitmq.also_read_notifications -}}
{{- end -}}
{{- if $readNotifications -}}
  {{- $port := required ".Values.logRouter.rabbitmq.port is missing" $.Values.logRouter.rabbitmq.port -}}
  {{- $urls = append $urls (include "log_router_rabbitmq_broker_urls" (list $ "rabbitmq_notifications" (required ".Values.rabbitmq_notifications.replicas is missing" $.Values.rabbitmq_notifications.replicas) $port)) -}}
{{- end -}}
{{- join "," $urls -}}
{{- end -}}

{{- define "log_router_common_envvars" }}
- name: LOG_ROUTER_LISTEN_ADDRESS
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_LISTEN_ADDRESS
- name: LOG_ROUTER_WAL_DIR
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_WAL_DIR
- name: LOG_ROUTER_DEBUG
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_DEBUG
- name: LOG_ROUTER_FLUSH_INTERVAL
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_FLUSH_INTERVAL
- name: LOG_ROUTER_SHUTDOWN_TIMEOUT
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_SHUTDOWN_TIMEOUT
- name: LOG_ROUTER_INGEST_CHANNEL_CAPACITY
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_INGEST_CHANNEL_CAPACITY
- name: LOG_ROUTER_MAX_CONCURRENT_FLUSHES
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_MAX_CONCURRENT_FLUSHES
# The configmap only renders this key when logRouter.max_buffer_memory_mb is
# set, hence optional: unset leaves the limiter off instead of failing the pod.
- name: LOG_ROUTER_MAX_BUFFER_MEMORY_MB
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_MAX_BUFFER_MEMORY_MB
      optional: true
- name: LOG_ROUTER_RABBITMQ_QUEUE
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_RABBITMQ_QUEUE
- name: LOG_ROUTER_RABBITMQ_EXCHANGE
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_RABBITMQ_EXCHANGE
- name: LOG_ROUTER_RABBITMQ_ROUTING_KEY
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_RABBITMQ_ROUTING_KEY
- name: LOG_ROUTER_RABBITMQ_PREFETCH
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_RABBITMQ_PREFETCH
- name: LOG_ROUTER_S3_ENDPOINT
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_S3_ENDPOINT
- name: LOG_ROUTER_S3_REGION
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_S3_REGION
- name: LOG_ROUTER_S3_BUCKET
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_S3_BUCKET
- name: LOG_ROUTER_S3_PREFIX
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_S3_PREFIX
- name: LOG_ROUTER_SWIFT_ENABLED
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_SWIFT_ENABLED
- name: LOG_ROUTER_SWIFT_SERVICE_TYPE
  valueFrom:
    configMapKeyRef:
      name: log-router-etc
      key: LOG_ROUTER_SWIFT_SERVICE_TYPE
{{- if .Values.logRouter.swift.enabled }}
# Keystone credentials for Swift/Ceph RGW authentication (hermes service account).
# Authenticates as ccadmin/cloud_admin — cloud_objectstore_admin role grants cross-account
# Ceph RGW access to all tenant buckets. Admin compliance bucket lives in ccadmin/master;
# LOG_ROUTER_SWIFT_ADMIN_ACCOUNT switches the admin client to that account at write time.
# Mirrors the keppel/deployment-health-monitor OS_* env block (alphabetized,
# explicit auth-version pins for gophercloud).
- name: LOG_ROUTER_SWIFT_ADMIN_ACCOUNT
  value: 'AUTH_{{ .Values.logRouter.swift.adminProjectID | required "logRouter.swift.adminProjectID must be set (ccadmin/master project UUID)" }}'
- name: OS_AUTH_URL
  value: "http://keystone.{{ $.Values.global.keystoneNamespace }}.svc.{{ $.Values.global.clusterDNSSearchDomain }}:5000/v3"
- name: OS_AUTH_VERSION
  value: '3'
- name: OS_IDENTITY_API_VERSION
  value: '3'
- name: OS_INTERFACE
  value: 'public'
- name: OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: log-router-secret
      key: OS_PASSWORD
- name: OS_PROJECT_DOMAIN_NAME
  value: 'ccadmin'
- name: OS_PROJECT_NAME
  value: 'cloud_admin'
- name: OS_REGION_NAME
  value: {{ required ".Values.global.region must be set when logRouter.swift.enabled=true (used for Swift endpoint catalog lookup)" $.Values.global.region | quote }}
- name: OS_USER_DOMAIN_NAME
  value: 'Default'
- name: OS_USERNAME
  value: 'hermes'
{{- end }}
- name: RABBITMQ_USER
  valueFrom:
    secretKeyRef:
      name: log-router-secret
      key: RABBITMQ_USER
- name: RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: log-router-secret
      key: RABBITMQ_PASSWORD
- name: RABBITMQ_URLS
  value: {{ include "log_router_rabbitmq_urls" . | quote }}
# Read-only connection to the hermes postgres for dataplane_config lookups.
# The log_router login user is a member of the log_router_reader NOLOGIN role
# (created by hermez's migration 001), which holds the SELECT grant on the
# dataplane_config table. Log-router fails closed on connection errors —
# all events still reach the admin tier (ccadmin/master) regardless.
- name: LOG_ROUTER_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: '{{ $.Release.Name }}-pguser-{{ $.Values.logRouter.hermesDb.user }}'
      key: postgres-password
- name: LOG_ROUTER_DB_URL
  value: "postgres://{{ $.Values.logRouter.hermesDb.user }}:$(LOG_ROUTER_DB_PASSWORD)@{{ $.Release.Name }}-postgresql.{{ $.Release.Namespace }}.svc:5432/hermes?sslmode=disable"
{{- end -}}
