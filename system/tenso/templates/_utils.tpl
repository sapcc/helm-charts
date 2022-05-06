{{- define "tenso_image" -}}
  {{ $.Values.global.registry }}/tenso:{{ $.Values.tenso.image_tag | required ".Values.tenso.image_tag is missing" }}
{{- end -}}

{{- define "tenso_environment" }}
- name:  OS_AUTH_URL
  value: "http://keystone.{{ $.Values.global.keystoneNamespace }}.svc.kubernetes.{{ $.Values.global.region }}.{{ $.Values.global.tld }}:5000/v3"
- name:  OS_AUTH_VERSION
  value: '3'
- name:  OS_IDENTITY_API_VERSION
  value: '3'
- name:  OS_INTERFACE
  value: internal
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
- name:  TENSO_DEBUG
  value: 'false'
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
- name: TENSO_ROUTES
  value: 'helm-release-from-concourse.v1 -> helm-release-to-elk.v1'
- name:  TENSO_WORKER_LISTEN_ADDRESS
  value: ':80'
{{- end -}}
