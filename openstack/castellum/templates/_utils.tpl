When passed via `helm upgrade --set`, the image tag is misinterpreted as a float64. So special care is needed to render it correctly.

{{- define "castellum_image" -}}
  {{- if typeIs "string" $.Values.castellum.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{- if typeIs "float64" .Values.castellum.image_tag -}}
      {{$.Values.castellum.image}}:{{$.Values.castellum.image_tag | printf "%0.f"}}
    {{- else -}}
      {{$.Values.castellum.image}}:{{$.Values.castellum.image_tag}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "castellum_common_envvars" }}
- name: CASTELLUM_DEBUG
  value: "false"
- name: CASTELLUM_ASSET_MANAGERS
  value: "nfs-shares,project-quota"
- name: CASTELLUM_DB_URI
  value: "postgres://postgres:{{ .Values.postgresql.postgresPassword }}@castellum-postgresql.{{ .Release.Namespace }}.svc/castellum?sslmode=disable"
- name: CASTELLUM_HTTP_LISTEN_ADDRESS
  value: ":8080"
- name: CASTELLUM_LOG_SCRAPES
  value: "true"
- name: CASTELLUM_NFS_PROMETHEUS_URL
  value: "http://prometheus-infra-collector.infra-monitoring.svc:9090"
- name: CASTELLUM_OSLO_POLICY_PATH
  value: /etc/castellum/policy.json
- name: CASTELLUM_SENTRY_DSN
  valueFrom: { secretKeyRef: { name: sentry, key: castellum.DSN.public } }
- name: CASTELLUM_RABBITMQ_URI
  value: "{{ .Values.castellum.rabbitmq.uri }}"
- name: CASTELLUM_RABBITMQ_QUEUE_NAME
  value: "{{ .Values.castellum.rabbitmq.queue_name }}"
- name: OS_AUTH_URL
  value: "http://keystone.{{ .Values.global.keystoneNamespace }}.svc.kubernetes.{{ .Values.global.region }}.{{ .Values.global.tld }}:5000/v3"
- name: OS_AUTH_VERSION
  value: "3"
- name: OS_IDENTITY_API_VERSION
  value: "3"
- name: OS_INTERFACE
  value: internal
- name: OS_PASSWORD
  value: {{ quote .Values.castellum.service_user.password }}
- name: OS_PROJECT_DOMAIN_NAME
  value: ccadmin
- name: OS_PROJECT_NAME
  value: cloud_admin
- name: OS_REGION_NAME
  value: {{ quote .Values.global.region }}
- name: OS_USER_DOMAIN_NAME
  value: Default
- name: OS_USERNAME
  value: castellum
{{- end -}}

{{- define "castellum_liveness_readiness_probes" }}
livenessProbe:
  httpGet:
    path: /healthcheck
    port: 8080
  timeoutSeconds: 10
  periodSeconds: 60
  initialDelaySeconds: 60
readinessProbe:
  httpGet:
    path: /healthcheck
    port: 8080
  timeoutSeconds: 5
  periodSeconds: 5
{{- end -}}
