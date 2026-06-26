- name: PORT
  value: {{ .Values.port | quote }}
- name: IDENTITY_ENDPOINT
  # prettier-ignore
  value: {{ .Values.identity_endpoint | default (printf "https://identity-3.%s.%s/v3" .Values.global.region .Values.global.tld) | quote }}
- name: CEPH_REGION
  value: {{ .Values.ceph_region | quote }}
- name: VITE_APP_TITLE
  value: {{ .Values.app_title | quote }}
- name: VITE_ELEKTRA_URL
  value: {{ printf "https://dashboard.%s.%s" .Values.global.region .Values.global.tld | quote }}
- name: VITE_DISABLE_DEFAULT_LOGIN
  value: {{ .Values.disable_default_login | quote }}
