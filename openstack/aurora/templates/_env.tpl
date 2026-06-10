- name: PORT
  value: "3000"
- name: IDENTITY_ENDPOINT
  # prettier-ignore
  value: {{ .Values.identity_endpoint | default (printf "https://identity-3.%s.%s/v3" .Values.global.region .Values.global.tld) | quote }}
- name: CEPH_REGION
  value: {{ .Values.ceph_region | quote }}
{{- if not .Values.prPreview.enabled }}
- name: FEEDBACK_RECIPIENT_EMAIL
  value: {{ .Values.feedback_recipient_email | quote }}
- name: LIMES_MAIL_SERVER_ENDPOINT
  # prettier-ignore
  value: {{ .Values.limes_mail_server_endpoint | default (printf "https://limes-mail-server-%s.%s" .Values.global.region .Values.global.tld) | quote }}  
- name: TECHNICAL_USER_NAME
  value: {{ .Values.technical_user_name | quote }}
- name: TECHNICAL_USER_PASSWORD
  value: {{ .Values.technical_user_password | quote }}
- name: TECHNICAL_USER_DOMAIN
  value: {{ .Values.technical_user_domain | quote }}
{{- end }}