- name: RAILS_ENV
  value: {{ .Values.rails_env | quote }}
- name: HAS_KEYSTONE_ROUTER
  value: {{ .Values.has_keystone_router | quote }}
- name: MONSOON_DASHBOARD_REGION
  value: {{ .Values.monsoon_dashboard_region | quote }}
- name: MONSOON_DASHBOARD_LANDSCAPE
  value: {{ .Values.monsoon_dashboard_landscape | quote }}
- name: MONSOON_DASHBOARD_MAIL_SERVER
  value: {{ .Values.monsoon_dashboard_mail_server | quote }}
- name: MONSOON_DASHBOARD_AVATAR_URL
  value: {{ .Values.monsoon_dashboard_avatar_url | quote }}
- name: MONSOON_DASHBOARD_CAM_URL
  value: {{ .Values.monsoon_dashboard_cam_url | quote }}
{{- if .Values.monsoon_openstack_auth_api_endpoint }}
- name: MONSOON_OPENSTACK_AUTH_API_ENDPOINT
  value: {{ .Values.monsoon_openstack_auth_api_endpoint | quote }}
{{ else }}
- name: MONSOON_OPENSTACK_AUTH_API_ENDPOINT
  value: {{ include "keystone_url" . | quote }}
{{- end }}
- name: MONSOON_OPENSTACK_AUTH_API_USERID
  value: {{ .Values.monsoon_openstack_auth_api_userid | quote }}
- name: MONSOON_OPENSTACK_AUTH_API_DOMAIN
  value: {{ .Values.monsoon_openstack_auth_api_domain | quote }}
- name: TWO_FACTOR_AUTHENTICATION
  value: {{ .Values.two_factor_authentication | quote }}
- name: TWO_FACTOR_RADIUS_SERVERS
  value: {{ .Values.two_factor_radius_servers | quote }}
- name: TWO_FACTOR_RADIUS_SECRET
  value: {{ .Values.two_factor_radius_secret | quote }}
- name: TWO_FACTOR_AUTH_DOMAINS
  value: {{ .Values.two_factor_auth_domains | quote }}
- name: SWIFT_RESELLERADMIN_PROJECT
  value: {{ .Values.swift_reselleradmin_project | quote }}
- name: SWIFT_RESELLERADMIN_ROLE
  value: {{ .Values.swift_reselleradmin_role | quote }}
- name: SWIFT_RESELLERADMIN_PROJECT_DOMAIN
  value: {{ .Values.swift_reselleradmin_project_domain | quote }}
- name: SWIFT_RESELLERADMIN_REGION
  value: {{ .Values.swift_reselleradmin_region | quote }}
- name: MONSOON_DB_PASSWORD
  valueFrom: { secretKeyRef:    { name: {{ template "postgresql.fullname" . }}, key: postgres-password } }
- name: MONSOON_OPENSTACK_AUTH_API_PASSWORD
  valueFrom: { secretKeyRef:    { name: elektra, key: monsoon.openstack.auth.api.password } }
- name: MONSOON_RAILS_SECRET_TOKEN
  valueFrom: { secretKeyRef:    { name: elektra, key: monsoon.rails.secret.token } }
{{- if .Values.sentryDSN }}
- name: SENTRY_DSN
{{- if eq .Values.sentryDSN "auto" }}
  valueFrom: { secretKeyRef:    { name: sentry, key: elektra.DSN } }
{{- else }}
  valueFrom: { secretKeyRef:    { name: {{ .Release.Name }}, key: sentryDSN } }
{{- end }}
{{- end }}
- name: DOMAIN_MASTERDATA_INHERITANCE_BLACKLIST
  value: hcp03,monsoon3
