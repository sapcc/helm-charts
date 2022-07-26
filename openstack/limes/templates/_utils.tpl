{{- define "limes_image" -}}
  {{- if contains "DEFINED" $.Values.limes.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{$.Values.global.registry}}/limes:{{$.Values.limes.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "limes_common_envvars" }}
- name: LIMES_AUDIT_ENABLE
  value: "{{ .Values.limes.environment_variables.audit_enable }}"
- name: LIMES_AUDIT_RABBITMQ_HOSTNAME
  value: "{{ .Values.limes.environment_variables.rabbitmq_hostname }}"
- name: LIMES_AUDIT_RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: limes-secret
      key: rabbitmq_password
- name: LIMES_AUTHORITATIVE
  value: "true"
- name: LIMES_CONSTRAINTS_PATH
  value: "{{ .Values.limes.environment_variables.constraints }}"
- name: LIMES_DEBUG
  value: '0'
- name: LIMES_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: limes-secret
      key: postgres_password
- name: LIMES_DB_HOSTNAME
  value: "limes-postgresql.{{ .Release.Namespace }}.svc"
- name: LIMES_DB_CONNECTION_OPTIONS
  value: "sslmode=disable"
- name: LIMES_COLLECTOR_DATA_METRICS_EXPOSE
  value: "true"
- name: LIMES_COLLECTOR_DATA_METRICS_SKIP_ZERO
  value: "true"
- name: LIMES_OPA_DOMAIN_QUOTA_POLICY_PATH
  value: "{{ .Values.limes.environment_variables.domain_quota_policy_path }}"
- name: LIMES_OPA_PROJECT_QUOTA_POLICY_PATH
  value: "{{ .Values.limes.environment_variables.project_quota_policy_path }}"
- name: OS_AUTH_URL
  value: "{{ .Values.limes.environment_variables.os_auth_url }}"
- name: OS_USER_DOMAIN_NAME
  value: "{{ .Values.limes.environment_variables.os_user_domain_name }}"
- name: OS_USERNAME
  value: "{{ .Values.limes.environment_variables.os_username }}"
- name: OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: limes-secret
      key: os_password
- name: OS_PROJECT_DOMAIN_NAME
  value: "{{ .Values.limes.environment_variables.os_project_domain_name }}"
- name: OS_PROJECT_NAME
  value: "{{ .Values.limes.environment_variables.os_project_name }}"
- name: OS_REGION_NAME
  value: "{{ .Values.limes.environment_variables.os_region_name }}"
{{- end -}}
