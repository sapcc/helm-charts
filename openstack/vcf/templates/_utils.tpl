{{- define "vcf_image" -}}
  {{- if contains "DEFINED" $.Values.image_tag -}}
    {{ required "This release should be installed by the deployment pipeline!" "" }}
  {{- else -}}
    {{ $.Values.global.registryAlternateRegion }}/vcf-automation:{{$.Values.image_tag}}
  {{- end -}}
{{- end -}}

{{- define "vcf_environment" }}

- name:  AUTOMATION_PORT
  value: '80'
- name: AUTOMATION_OS_REGION
  value: '{{ .Values.global.region }}'
- name: PULUMI_BACKEND_URL
  value: file:///pulumi/automation/etc
- name: AUTOMATION_WORK_DIR
  value: /pulumi/automation
- name: AUTOMATION_PROJECT_ROOT
  value: /pulumi/automation/projects
- name: AUTOMATION_CONFIG_DIR
  value: /pulumi/automation/etc
- name: AUTOMATION_STATIC_PATH
  value: /pulumi/automation/static
- name: AUTOMATION_TEMPLATE_PATH
  value: /pulumi/automation/templates

- name: PULUMI_CONFIG_PASSPHRASE
  valueFrom:
    secretKeyRef:
      name: vcf-secrets
      key: pulumi_config_passphrase
- name: AUTOMATION_OS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: vcf-secrets
      key: os_password
- name: AUTOMATION_OS_USERNAME
  valueFrom:
    secretKeyRef:
      name: vcf-secrets
      key: os_username
- name: AUTOMATION_VMWARE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: vcf-secrets
      key: vmware_password
{{- end -}}
