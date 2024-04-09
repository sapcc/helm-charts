{{- define "castellum_image" -}}
  {{- if $.Values.castellum.image_tag -}}
    {{$.Values.global.registry}}/castellum:{{$.Values.castellum.image_tag}}
  {{- else -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- end -}}
{{- end -}}

{{- define "castellum_common_envvars" }}
- name: CASTELLUM_DEBUG
  value: "false"
- name: CASTELLUM_ASSET_MANAGERS
  value: "{{ $.Values.castellum.asset_managers | join "," }}"
- name: CASTELLUM_DB_USERNAME
  value: 'castellum'
- name: CASTELLUM_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: '{{ $.Release.Name }}-pguser-castellum'
      key: 'postgres-password'
- name: CASTELLUM_DB_HOSTNAME
  value: "castellum-postgresql.{{ .Release.Namespace }}.svc"
- name: CASTELLUM_DB_CONNECTION_OPTIONS
  value: "sslmode=disable"
- name: CASTELLUM_HTTP_LISTEN_ADDRESS
  value: ":8080"
- name: CASTELLUM_LOG_SCRAPES
  value: "true"
{{- if $.Values.castellum.asset_managers | has "nfs-shares" }}
- name: CASTELLUM_NFS_DISCOVERY_PROMETHEUS_URL
  value: "http://prometheus-openstack.prometheus-openstack.svc:9090"
- name: CASTELLUM_NFS_PROMETHEUS_URL
  value: "http://prometheus-storage.infra-monitoring.svc:9090"
{{- end }}
- name: CASTELLUM_OSLO_POLICY_PATH
  value: /etc/castellum/policy.yaml
- name: CASTELLUM_RABBITMQ_QUEUE_NAME
  value: notifications.info
- name: CASTELLUM_RABBITMQ_USERNAME
  valueFrom:
    secretKeyRef:
      name: castellum-secret
      key: rabbitmq_username
- name: CASTELLUM_RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: castellum-secret
      key: rabbitmq_password
- name: CASTELLUM_RABBITMQ_HOSTNAME
  value: hermes-rabbitmq-notifications.hermes.svc
{{- if $.Values.castellum.asset_managers | has "server-groups" }}
- name: CASTELLUM_SERVERGROUPS_LOCAL_ROLES
  value: "member,keymanager_viewer"
- name: CASTELLUM_SERVERGROUPS_PROMETHEUS_URL
  value: "https://metrics-internal.scaleout.{{ .Values.global.region }}.cloud.sap"
- name: CASTELLUM_SERVERGROUPS_PROMETHEUS_CERT
  value: /etc/castellum-certs/prometheus-vmware.cert.pem
- name: CASTELLUM_SERVERGROUPS_PROMETHEUS_KEY
  value: /etc/castellum-certs/prometheus-vmware.key.pem
{{- end }}
- name: OS_AUTH_URL
  value: "http://keystone.{{ .Values.global.keystoneNamespace }}.svc.kubernetes.{{ .Values.global.region }}.{{ .Values.global.tld }}:5000/v3"
- name: OS_AUTH_VERSION
  value: "3"
- name: OS_IDENTITY_API_VERSION
  value: "3"
- name: OS_INTERFACE
  value: internal
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
- name: OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: castellum-secret
      key: service_user_password
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
