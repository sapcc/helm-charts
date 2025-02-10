{{- define "campfire_image" -}}
  {{- if $.Values.campfire.image_tag -}}
    {{$.Values.global.registry}}/campfire:{{$.Values.campfire.image_tag}}   
  {{- else -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- end -}}
{{- end -}}

{{- define "campfire_openstack_envvars" }}
- name: OS_AUTH_URL
  value: "http://keystone.{{ $.Values.global.keystoneNamespace }}.svc.kubernetes.{{ $.Values.global.region }}.{{ $.Values.global.tld }}:5000/v3"
- name: OS_USER_DOMAIN_NAME
  value: "ccadmin"
- name: OS_USERNAME
  value: "limes"
- name: OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: campfire-secret
      key: os_password
- name: OS_PROJECT_DOMAIN_NAME
  value: "ccadmin"
- name: OS_PROJECT_NAME
  value: "master"
- name: OS_REGION_NAME
  value: {{ quote $.Values.global.region }}
  
- name: MASTERDATA_AUTH_URL
  value: "http://keystone.{{ $.Values.global.keystoneNamespace }}.svc.kubernetes.{{ $.Values.global.region }}.{{ $.Values.global.tld }}:5000/v3"
- name: MASTERDATA_USER_DOMAIN_NAME
  value: "ccadmin"
- name: MASTERDATA_USERNAME
  value: "limes"
- name: MASTERDATA_PASSWORD
  valueFrom:
    secretKeyRef:
      name: campfire-secret
      key: os_password
- name: MASTERDATA_PROJECT_DOMAIN_NAME
  value: "ccadmin"
- name: MASTERDATA_PROJECT_NAME
  value: "cloud_admin"
{{- end }}

{{- define "campfire_smtp_envvars" }}
- name: SMTP_HOST
  value: "cronus.{{ $.Values.global.region }}.{{ $.Values.global.tld }}"
- name: SMTP_PORT
  value: "587"
- name: SMTP_FROM
  value: "noreply+%sender%@email.global.{{ $.Values.global.tld }}"
{{- end }}
