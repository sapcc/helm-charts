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
  value: "Default"
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
  value: "cloud_admin"
- name: OS_REGION_NAME
  value: {{ quote $.Values.global.region }}
  
- name: CRONUS_AUTH_URL
  value: "http://keystone.{{ $.Values.global.keystoneNamespace }}.svc.kubernetes.{{ $.Values.global.region }}.{{ $.Values.global.tld }}:5000/v3"
- name: CRONUS_USER_DOMAIN_NAME
  value: "Default"
- name: CRONUS_USERNAME
  value: "limes"
- name: CRONUS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: campfire-secret
      key: os_password
- name: CRONUS_PROJECT_DOMAIN_NAME
  value: "ccadmin"
- name: CRONUS_PROJECT_NAME
  value: "master"
- name: CRONUS_REGION_NAME
  value: {{ quote $.Values.global.region }}
{{- end }}

{{- define "campfire_smtp_envvars" }}
- name: SMTP_HOST
  value: "cronus.{{ $.Values.global.region }}.{{ $.Values.global.tld }}"
- name: SMTP_PORT
  value: "587"
- name: SMTP_FROM
  value: "noreply+%sender%@email.global.{{ $.Values.global.tld }}"
{{- end }}
