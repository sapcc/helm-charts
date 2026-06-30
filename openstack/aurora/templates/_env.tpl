{{- $host := .Values.ingress.host | default (printf "dashboard-aurora.%s.%s" .Values.global.region .Values.global.tld) -}}
{{- $parts := splitList "." $host -}}
{{- $cookieDomain := printf ".%s" (join "." (rest $parts)) -}}

- name: PORT
  value: {{ .Values.port | quote }}
- name: IDENTITY_ENDPOINT
  # prettier-ignore
  value: {{ .Values.identity_endpoint | default (printf "https://identity-3.%s.%s/v3" .Values.global.region .Values.global.tld) | quote }}
- name: CEPH_REGION
  value: {{ .Values.ceph_region | quote }}
- name: COOKIE_DOMAIN
  value: "{{ $cookieDomain }}"
