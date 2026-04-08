{{- define "log_router_image" -}}
  {{- if contains "DEFINED" $.Values.logRouter.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.global.registry}}/log-router:{{$.Values.logRouter.image_tag}}
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
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: log-router-secret
      key: AWS_ACCESS_KEY_ID
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: log-router-secret
      key: AWS_SECRET_ACCESS_KEY
- name: LOG_ROUTER_POLICY_FILE
  value: /etc/log-router/policy.json
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
- name: LOG_ROUTER_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: '{{ $.Release.Name }}-pguser-log_router'
      key: postgres-password
- name: LOG_ROUTER_DB_URL
  value: "postgres://log_router:$(LOG_ROUTER_DB_PASSWORD)@{{ $.Release.Name }}-postgresql.{{ $.Release.Namespace }}.svc:5432/log_router?sslmode=disable"
- name: OS_AUTH_URL
  value: "{{ $.Values.hermes.auth_url }}"
- name: OS_USERNAME
  value: "{{ $.Values.hermes.username }}"
- name: OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: log-router-secret
      key: OS_PASSWORD
- name: OS_USER_DOMAIN_NAME
  value: "Default"
- name: OS_PROJECT_NAME
  value: "cloud_admin"
- name: OS_PROJECT_DOMAIN_NAME
  value: "ccadmin"
{{- end -}}
