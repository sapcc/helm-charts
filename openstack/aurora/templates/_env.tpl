{{- $host := .Values.ingress.host | default (printf "dashboard-aurora.%s.%s" .Values.global.region .Values.global.tld) -}}
{{- $parts := splitList "." $host -}}
{{- $cookieDomain := printf ".%s" (join "." (rest $parts)) -}}

- name: PORT
  value: {{ .Values.port | quote }}
- name: IDENTITY_ENDPOINT
  value: {{ .Values.identity_endpoint | default (printf "http://keystone.%s.svc.kubernetes.%s.%s:5000/v3/auth/tokens" (default .Release.Namespace .Values.global.keystoneNamespace) .Values.global.region .Values.global.tld) | quote }}
- name: CEPH_REGION
  value: {{ .Values.ceph_region | quote }}
- name: DASHBOARD_COOKIE_NAME
  value: {{ .Values.dashboard_cookie_name | quote }}
- name: COOKIE_DOMAIN
  value: {{ $cookieDomain | quote }}

