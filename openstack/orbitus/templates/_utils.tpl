{{- define "orbitus_image" -}}
  {{- if not $.Values.orbitus.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registry }}/orbitus:{{ $.Values.orbitus.image_tag }}
  {{- end -}}
{{- end -}}

{{- define "orbitus_openstack_envvars" }}
{{- $region := .Values.global.region | required "missing value for .Values.global.region" }}
- name: OS_AUTH_URL
  value: "http://keystone.{{ $.Values.global.keystoneNamespace }}.svc.{{ $.Values.global.clusterDNSSearchDomain }}:5000/v3"
- name: OS_INTERFACE
  value: "internal"
- name: OS_USER_DOMAIN_NAME
  value: Default
- name: OS_USERNAME
  value: orbitus
- name: OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: orbitus-secret
      key: os_password
- name: OS_PROJECT_DOMAIN_NAME
  value: ccadmin
- name: OS_PROJECT_NAME
  value: cloud_admin
- name: OS_REGION_NAME
  value: {{ quote $region }}
{{- end -}}

{{- define "envvars_for_database" }}
{{- $ctx := index . 0 }}
{{- $db := index . 1 }}
- name: ORBITUS_DB_USERNAME
  value: '{{ $db }}'
- name: ORBITUS_DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: '{{ $ctx.Release.Name }}-pguser-{{ $db }}'
      key: 'postgres-password'
- name: ORBITUS_DB_HOSTNAME
  value: "orbitus-postgresql.{{ $ctx.Release.Namespace }}.svc"
- name: ORBITUS_DB_CONNECTION_OPTIONS
  value: "sslmode=disable"
{{- end -}}
