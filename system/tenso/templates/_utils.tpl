{{- define "tenso_image" -}}
  {{ $.Values.global.registry }}/tenso:{{ $.Values.tenso.image_tag | required ".Values.tenso.image_tag is missing" }}
{{- end -}}

{{- define "tenso_environment" }}
- name:  TENSO_DEBUG
  value: 'false'
- name:  OS_AUTH_URL
  value: "http://identity-3.{{ $.Values.global.region }}.{{ $.Values.global.tld }}/v3"
- name:  OS_AUTH_VERSION
  value: '3'
- name:  OS_IDENTITY_API_VERSION
  value: '3'
- name:  OS_INTERFACE
  value: public # Tenso lives in scaleout and thus needs to go through the public API endpoints
- name:  OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: tenso-secret
      key: service_user_password
- name:  OS_PROJECT_DOMAIN_NAME
  value: 'ccadmin'
- name:  OS_PROJECT_NAME
  value: 'master'
- name:  OS_REGION_NAME
  value: {{ quote $.Values.global.region }}
- name:  OS_USER_DOMAIN_NAME
  value: 'Default'
- name:  OS_USERNAME
  value: 'tenso'
- name:  TENSO_API_LISTEN_ADDRESS
  value: ':80'
- name:  TENSO_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: tenso-secret
      key: postgres_password
- name: TENSO_DB_HOSTNAME
  value: "{{ .Release.Name }}-postgresql"
- name: TENSO_DB_CONNECTION_OPTIONS
  value: 'sslmode=disable'
- name: TENSO_OSLO_POLICY_PATH
  value: '/etc/tenso/policy.yaml'
- name: TENSO_ROUTES
  value: 'helm-deployment-from-concourse.v1 -> helm-deployment-to-elk.v1'
- name:  TENSO_WORKER_LISTEN_ADDRESS
  value: ':80'
{{- end -}}
