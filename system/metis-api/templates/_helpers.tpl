{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "metisAPI.chart" -}}
{{- printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "name" -}}
{{- "metis-api" -}}
{{- end -}}


{{- define "os_environment" }}
- name:  OS_AUTH_URL
  value: "http://identity-3.{{ $.Values.global.region }}.{{ $.Values.global.tld }}/v3"
- name:  OS_AUTH_VERSION
  value: '3'
- name:  OS_IDENTITY_API_VERSION
  value: '3'
- name:  OS_INTERFACE
  value: public
- name: OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: metis-api-secrets
      key: metisServicePW
- name:  OS_PROJECT_DOMAIN_NAME
  value: 'Default'
- name:  OS_PROJECT_NAME
  value: 'service'
- name:  OS_REGION_NAME
  value: {{ quote $.Values.global.region }}
- name:  OS_USER_DOMAIN_NAME
  value: 'Default'
- name:  OS_USERNAME
  value: 'metis'
- name: OSLO_POLICY_PATH
  value: '/etc/metis/policy.yaml'
{{- end }}
