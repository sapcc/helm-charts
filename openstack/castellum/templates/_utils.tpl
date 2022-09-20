{{- define "castellum_image" -}}
  {{- if contains "DEFINED" $.Values.castellum.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.global.registry}}/castellum:{{$.Values.castellum.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "castellum_common_envvars" }}
- name: CASTELLUM_DEBUG
  value: "false"
- name: CASTELLUM_ASSET_MANAGERS
  value: "nfs-shares,project-quota,server-groups"
- name: CASTELLUM_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: castellum-secret
      key: postgres_password
- name: CASTELLUM_DB_HOSTNAME
  value: "castellum-postgresql.{{ .Release.Namespace }}.svc"
- name: CASTELLUM_DB_CONNECTION_OPTIONS
  value: "sslmode=disable"
- name: CASTELLUM_HTTP_LISTEN_ADDRESS
  value: ":8080"
- name: CASTELLUM_LOG_SCRAPES
  value: "true"
- name: CASTELLUM_MAX_ASSET_SIZES
  value: "nfs-shares.*=20480" # 20480 GiB = 20 TiB
  # ^ The Manila limit comes from the "provisioning:max_share_extend_size" setting in
  # `openstack/manila/templates/_helpers.tpl`. The limit in Manila only applies to
  # the "default" share type. The "hypervisor_storage" share types are not limited,
  # but those are usually not autoscaled anyway, so it's not a problem as of now.
- name: CASTELLUM_NFS_PROMETHEUS_URL
  value: "http://prometheus-infra-collector.infra-monitoring.svc:9090"
- name: CASTELLUM_OSLO_POLICY_PATH
  value: /etc/castellum/policy.yaml
- name: CASTELLUM_RABBITMQ_QUEUE_NAME
  value: "{{ .Values.castellum.rabbitmq.queue_name }}"
- name: CASTELLUM_RABBITMQ_USERNAME
  value: "{{ .Values.castellum.rabbitmq.username }}"
- name: CASTELLUM_RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: castellum-secret
      key: rabbitmq_password
- name: CASTELLUM_RABBITMQ_HOSTNAME
  value: "{{ .Values.castellum.rabbitmq.hostname }}"
- name: CASTELLUM_SERVERGROUPS_LOCAL_ROLES
  value: "member,keymanager_viewer"
- name: CASTELLUM_SERVERGROUPS_PROMETHEUS_URL
  value: "http://prometheus-vmware.vmware-monitoring.svc:9090"
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
