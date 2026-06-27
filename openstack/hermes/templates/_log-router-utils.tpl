{{- define "log_router_image" -}}
  {{- if contains "DEFINED" $.Values.logRouter.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.global.registry}}/hermes-logrouter:{{$.Values.logRouter.image_tag}}
  {{- end -}}
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
# cloud_objectstore_admin in ccadmin/cloud_admin grants cross-tenant RGW access.
# Mirrors the keppel/deployment-health-monitor OS_* env block (alphabetized,
# explicit auth-version pins for gophercloud).
- name: OS_AUTH_URL
  value: "http://keystone.{{ $.Values.global.keystoneNamespace }}.svc.{{ $.Values.global.clusterDNSSearchDomain }}:5000/v3"
- name: OS_AUTH_VERSION
  value: '3'
- name: OS_IDENTITY_API_VERSION
  value: '3'
- name: OS_INTERFACE
  value: 'internal'
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
- name: RABBITMQ_URL
  value: "amqp://$(RABBITMQ_USER):$(RABBITMQ_PASSWORD)@{{ $.Release.Name }}-rabbitmq-notifications.{{ $.Release.Namespace }}.svc:{{ $.Values.logRouter.rabbitmq.port }}/"
# Read-only connection to the hermes postgres for dataplane_config lookups.
# The log_router login user is a member of the log_router_reader NOLOGIN role
# (created by hermez's migration 001), which holds the SELECT grant on the
# dataplane_config table. Log-router fails closed on connection errors —
# all events still reach the admin tier (ccadmin/master) regardless.
- name: LOG_ROUTER_HERMES_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: '{{ $.Release.Name }}-pguser-{{ $.Values.logRouter.hermesDb.user }}'
      key: postgres-password
- name: LOG_ROUTER_HERMES_DB_URL
  value: "postgres://{{ $.Values.logRouter.hermesDb.user }}:$(LOG_ROUTER_HERMES_DB_PASSWORD)@{{ $.Release.Name }}-postgresql.{{ $.Release.Namespace }}.svc:5432/hermes?sslmode=disable"
{{- end -}}
